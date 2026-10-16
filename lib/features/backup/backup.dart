import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../items/data/vault_store.dart';
import '../items/domain/vault.dart';
import '../items/providers.dart';

/// A whole cabinet as one file: `vault.json` + `photos/` + `docs/` and a
/// small `backup.json` that says what made it. A plain zip on purpose:
/// the user can open it on a computer, and the app adds no encryption of
/// its own (that would change the App Store export-compliance answer);
/// where it is kept — iCloud Drive, Files, a Mac — protects it.
///
/// Built and read in a background isolate, file to file, without holding
/// the archive in memory: a 500-photo cabinet does not freeze the screen
/// or spike memory. Photos and PDFs are stored, not deflated — they are
/// already compressed, and deflating them costs seconds for ~1 % gain.
const backupFormat = 1;

/// What a backup holds, read before anything on the phone is touched.
class BackupSummary {
  const BackupSummary({required this.items, required this.created});
  final int items;
  final DateTime? created;
}

class BackupInvalid implements Exception {
  const BackupInvalid(this.reason);
  final String reason;
  @override
  String toString() => 'BackupInvalid($reason)';
}

/// Only these paths are ever written on restore; anything else in the zip
/// (a `../` path, a stray `__MACOSX/`) is skipped, so a crafted file cannot
/// write outside the vault folder.
final _allowed = RegExp(r'^(vault\.json|backup\.json|(photos|docs)/[A-Za-z0-9._-]+)$');

/// The vault folder, when the cabinet lives on disk (not in tests or the
/// web preview, where backup is not offered).
final backupDirProvider = Provider<Directory?>((ref) {
  final store = ref.watch(vaultStoreProvider);
  return store is LocalVaultStore ? store.dir : null;
});

/// Writes `<out>/<name>` from [vaultDir]; returns the file.
Future<File> makeBackup(Directory vaultDir, Directory out, String name, DateTime now) =>
    Isolate.run(() => _make(vaultDir.path, out.path, name, now));

Future<File> _make(String vault, String out, String name, DateTime now) async {
  final target = File('$out/$name');
  final enc = ZipFileEncoder()..create(target.path);
  try {
    final json = File('$vault/vault.json');
    final items = await json.exists()
        ? Vault.fromJson(jsonDecode(await json.readAsString()) as Map<String, dynamic>).items.length
        : 0;
    final meta = File('$out/backup.json');
    await meta.writeAsString(jsonEncode({'format': backupFormat, 'created': now.toIso8601String(), 'items': items}));
    await enc.addFile(meta, 'backup.json', ZipFileEncoder.gzip);
    if (await json.exists()) await enc.addFile(json, 'vault.json', ZipFileEncoder.gzip);
    for (final sub in const ['photos', 'docs']) {
      final d = Directory('$vault/$sub');
      if (!await d.exists()) continue;
      await for (final f in d.list()) {
        if (f is File) await enc.addFile(f, '$sub/${f.uri.pathSegments.last}', ZipFileEncoder.store);
      }
    }
    await enc.close();
    await meta.delete();
    return target;
  } catch (_) {
    await enc.close();
    if (await target.exists()) await target.delete();
    rethrow;
  }
}

/// Unpacks [zip] next to [vaultDir] and checks it, without touching the
/// current cabinet. Call [commitRestore] with the result to swap it in.
Future<(Directory, BackupSummary)> stageRestore(File zip, Directory vaultDir) =>
    Isolate.run(() => _stage(zip.path, vaultDir.path));

Future<(Directory, BackupSummary)> _stage(String zip, String vault) async {
  final staging = Directory('$vault.restore');
  if (await staging.exists()) await staging.delete(recursive: true);
  await staging.create(recursive: true);
  final input = InputFileStream(zip);
  try {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeStream(input);
    } catch (_) {
      throw const BackupInvalid('not a zip');
    }
    for (final f in archive.files) {
      if (!f.isFile || !_allowed.hasMatch(f.name)) continue;
      final dest = File('${staging.path}/${f.name}');
      await dest.parent.create(recursive: true);
      final o = OutputFileStream(dest.path);
      f.writeContent(o);
      await o.close();
    }
  } finally {
    await input.close();
  }

  final meta = File('${staging.path}/backup.json');
  final json = File('${staging.path}/vault.json');
  if (!await meta.exists() || !await json.exists()) {
    await staging.delete(recursive: true);
    throw const BackupInvalid('missing files');
  }
  final m = jsonDecode(await meta.readAsString()) as Map<String, dynamic>;
  // A backup from a newer build may hold fields this one would drop on the
  // next save; refuse rather than lose them.
  if ((m['format'] as int? ?? 0) > backupFormat) {
    await staging.delete(recursive: true);
    throw const BackupInvalid('newer format');
  }
  final Vault v;
  try {
    v = Vault.fromJson(jsonDecode(await json.readAsString()) as Map<String, dynamic>);
  } catch (_) {
    await staging.delete(recursive: true);
    throw const BackupInvalid('unreadable cabinet');
  }
  await meta.delete();
  return (staging, BackupSummary(items: v.items.length, created: DateTime.tryParse(m['created'] as String? ?? '')));
}

/// Swaps the staged folder in: two renames on the same volume, so a crash
/// leaves either the old cabinet or the new one, never half of each.
Future<void> commitRestore(Directory staging, Directory vaultDir) async {
  final old = Directory('${vaultDir.path}.old');
  if (await old.exists()) await old.delete(recursive: true);
  if (await vaultDir.exists()) await vaultDir.rename(old.path);
  await staging.rename(vaultDir.path);
  if (await old.exists()) await old.delete(recursive: true);
}

Future<void> discardRestore(Directory staging) async {
  if (await staging.exists()) await staging.delete(recursive: true);
}

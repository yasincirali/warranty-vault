import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/features/backup/backup.dart';
import 'package:warranty_vault/features/items/data/demo_vault.dart';
import 'package:warranty_vault/features/items/domain/vault.dart';

late Directory _tmp;

Future<Directory> _vault(String name, {int photos = 2, int photoBytes = 1000}) async {
  final d = Directory('${_tmp.path}/$name');
  await Directory('${d.path}/photos').create(recursive: true);
  await Directory('${d.path}/docs').create(recursive: true);
  await File('${d.path}/vault.json').writeAsString(jsonEncode(demoVault().toJson()));
  final r = Random(1);
  for (var i = 0; i < photos; i++) {
    await File('${d.path}/photos/p$i.png').writeAsBytes(List.generate(photoBytes, (_) => r.nextInt(256)));
  }
  await File('${d.path}/docs/fis.pdf').writeAsBytes(utf8.encode('%PDF-1.4 sample'));
  return d;
}

void main() {
  setUp(() async => _tmp = await Directory.systemTemp.createTemp('wv'));
  tearDown(() async => _tmp.delete(recursive: true));

  test('a backup restores the same cabinet, photos and papers into another phone', () async {
    final a = await _vault('a');
    final out = await Directory('${_tmp.path}/out').create();
    final zip = await makeBackup(a, out, 'b.zip', DateTime.utc(2026, 10, 17));

    final b = Directory('${_tmp.path}/b');
    await b.create();
    await File('${b.path}/vault.json').writeAsString(jsonEncode(const Vault().toJson()));
    final (staging, summary) = await stageRestore(zip, b);
    expect(summary.items, demoVault().items.length);
    expect(summary.created, DateTime.utc(2026, 10, 17));
    // Nothing on the phone changes until the user confirms.
    expect(jsonDecode(await File('${b.path}/vault.json').readAsString())['items'], isEmpty);

    await commitRestore(staging, b);
    expect(await File('${b.path}/photos/p1.png').readAsBytes(), await File('${a.path}/photos/p1.png').readAsBytes());
    expect(await File('${b.path}/docs/fis.pdf').exists(), isTrue);
    expect(await File('${b.path}/backup.json').exists(), isFalse);
    expect(await Directory('${b.path}.old').exists(), isFalse);
    expect(await staging.exists(), isFalse);
  });

  test('a file that is not a backup is refused and leaves nothing behind', () async {
    final b = await _vault('b');
    final junk = await File('${_tmp.path}/x.zip').writeAsString('not a zip');
    await expectLater(stageRestore(junk, b), throwsA(isA<BackupInvalid>()));

    final empty = Archive()..add(ArchiveFile.bytes('hello.txt', utf8.encode('hi')));
    final notOurs = await File('${_tmp.path}/y.zip').writeAsBytes(ZipEncoder().encodeBytes(empty));
    await expectLater(stageRestore(notOurs, b), throwsA(isA<BackupInvalid>()));
    expect(await Directory('${b.path}.restore').exists(), isFalse);
  });

  test('paths outside the vault are never written (zip slip)', () async {
    final b = await _vault('b');
    final ar = Archive()
      ..add(ArchiveFile.bytes('backup.json', utf8.encode(jsonEncode({'format': 1}))))
      ..add(ArchiveFile.bytes('vault.json', utf8.encode(jsonEncode(const Vault().toJson()))))
      ..add(ArchiveFile.bytes('../evil.txt', utf8.encode('x')))
      ..add(ArchiveFile.bytes('photos/../../evil2.txt', utf8.encode('x')));
    final zip = await File('${_tmp.path}/z.zip').writeAsBytes(ZipEncoder().encodeBytes(ar));
    final (staging, _) = await stageRestore(zip, b);
    expect(await File('${_tmp.path}/evil.txt').exists(), isFalse);
    expect(await File('${_tmp.path}/evil2.txt').exists(), isFalse);
    await discardRestore(staging);
  });

  test('a backup from a newer build is refused instead of losing its fields', () async {
    final b = await _vault('b');
    final ar = Archive()
      ..add(ArchiveFile.bytes('backup.json', utf8.encode(jsonEncode({'format': backupFormat + 1}))))
      ..add(ArchiveFile.bytes('vault.json', utf8.encode(jsonEncode(const Vault().toJson()))));
    final zip = await File('${_tmp.path}/n.zip').writeAsBytes(ZipEncoder().encodeBytes(ar));
    await expectLater(stageRestore(zip, b), throwsA(isA<BackupInvalid>()));
  });

  test('performance: 150 photos (60 MB) back up and restore in a background isolate', () async {
    final a = await _vault('big', photos: 150, photoBytes: 400 << 10);
    final out = await Directory('${_tmp.path}/out').create();
    final sw = Stopwatch()..start();
    final zip = await makeBackup(a, out, 'big.zip', DateTime.utc(2026, 10, 17));
    final make = sw.elapsedMilliseconds;
    sw.reset();
    final (staging, summary) = await stageRestore(zip, Directory('${_tmp.path}/c'));
    final restore = sw.elapsedMilliseconds;
    // ignore: avoid_print
    print('backup 60 MB: make $make ms, stage $restore ms, zip ${(await zip.length()) >> 20} MB');
    expect(summary.items, greaterThan(0));
    // Stored, not deflated: the zip is about the size of the photos.
    expect(await zip.length(), lessThan((61 << 20)));
    await discardRestore(staging);
  });
}

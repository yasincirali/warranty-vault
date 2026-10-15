import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import '../domain/vault.dart';

/// Where the cabinet lives. v1 is local-first: the TestFlight build needs no
/// account and no server, and the user's photos never leave the phone.
/// Sync to Supabase comes later behind this same interface.
abstract interface class VaultStore {
  Future<Vault> load();
  Future<void> save(Vault vault);

  /// Stores a product photo and returns its path relative to the vault.
  Future<String> savePhoto(String fileName, Uint8List png);

  ImageProvider photo(String relativePath);
}

/// `asset:demo/x.png` → a bundled picture (sample cabinet).
ImageProvider? bundledPhoto(String path) =>
    path.startsWith('asset:') ? AssetImage('assets/${path.substring(6)}') : null;

/// JSON file + PNG photos in Application Support (included in the user's
/// device backup, hidden from the Files app).
class LocalVaultStore implements VaultStore {
  LocalVaultStore(this.dir);
  final Directory dir;

  File get _file => File('${dir.path}/vault.json');

  @override
  Future<Vault> load() async {
    if (!await _file.exists()) return const Vault();
    final raw = await _file.readAsString();
    return Vault.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(Vault vault) async {
    await dir.create(recursive: true);
    // Write-then-rename: a crash mid-write leaves the previous vault intact
    // instead of a half-written file that would load as an empty cabinet.
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(jsonEncode(vault.toJson()), flush: true);
    await tmp.rename(_file.path);
  }

  @override
  Future<String> savePhoto(String fileName, Uint8List png) async {
    final rel = 'photos/$fileName';
    final f = File('${dir.path}/$rel');
    await f.parent.create(recursive: true);
    await f.writeAsBytes(png, flush: true);
    return rel;
  }

  @override
  ImageProvider photo(String relativePath) => bundledPhoto(relativePath) ?? FileImage(File('${dir.path}/$relativePath'));
}

/// In-memory store: widget tests, screenshots, and the default when no
/// folder was resolved.
class MemoryVaultStore implements VaultStore {
  MemoryVaultStore([this._vault = const Vault()]);
  Vault _vault;
  final _photos = <String, Uint8List>{};

  Vault get current => _vault;

  @override
  Future<Vault> load() async => _vault;

  @override
  Future<void> save(Vault vault) async => _vault = vault;

  @override
  Future<String> savePhoto(String fileName, Uint8List png) async {
    final rel = 'photos/$fileName';
    _photos[rel] = png;
    return rel;
  }

  @override
  ImageProvider photo(String relativePath) =>
      bundledPhoto(relativePath) ?? MemoryImage(_photos[relativePath] ?? _transparentPixel);
}

final _transparentPixel = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');

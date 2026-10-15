import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/items/data/demo_vault.dart';
import 'features/items/data/vault_store.dart';
import 'features/items/providers.dart';
import 'features/settings/settings.dart';

/// Sample cabinet in memory, no device storage: design reviews in a browser
/// (`flutter run -d chrome -t lib/main_preview.dart`) and store screenshots.
void main() => runApp(
  ProviderScope(
    overrides: [
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13)),
      // Turkish by default for design reviews; Ayarlar switches it.
      settingsStoreProvider.overrideWithValue(MemorySettingsStore({'language': 'tr'})),
      vaultStoreProvider.overrideWithValue(
        MemoryVaultStore(demoVault(desk: 'Çalışma masası', living: 'Salon', kitchen: 'Mutfak')),
      ),
    ],
    child: const WarrantyVaultApp(),
  ),
);

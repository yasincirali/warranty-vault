import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/items/data/demo_vault.dart';
import 'features/items/data/vault_store.dart';
import 'features/items/providers.dart';

/// Sample cabinet in memory, no device storage: design reviews in a browser
/// (`flutter run -d chrome -t lib/main_preview.dart`) and store screenshots.
void main() => runApp(ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 13)),
        vaultStoreProvider.overrideWithValue(MemoryVaultStore(demoVault(desk: 'Çalışma masası', living: 'Salon', kitchen: 'Mutfak'))),
      ],
      child: const WarrantyVaultApp(),
    ));

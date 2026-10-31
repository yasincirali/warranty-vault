import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'features/items/data/vault_store.dart';
import 'features/items/providers.dart';
import 'features/reminders/reminders.dart';
import 'features/review/review_prompt.dart';
import 'features/settings/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Upright only, on Android too (iOS says so in Info.plist): the cabinet
  // is a tall piece of furniture; sideways it shrank to a strip under the
  // header and the add button (Rafım Ar-Ge 31 Oct).
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Without --dart-define keys there is no backend; there is no fallback
  // URL or key in source on purpose. v1 keeps the cabinet on the device
  // either way (local-first), so the TestFlight build needs no keys.
  if (Env.hasBackend) {
    await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabaseAnonKey);
  }
  final support = await getApplicationSupportDirectory();
  final store = LocalVaultStore(Directory('${support.path}/vault'));
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        vaultStoreProvider.overrideWithValue(store),
        settingsStoreProvider.overrideWithValue(PrefsSettingsStore(prefs)),
        if (Platform.isIOS || Platform.isAndroid) reminderSchedulerProvider.overrideWithValue(LocalReminderScheduler()),
        if (Platform.isIOS || Platform.isAndroid) reviewRequesterProvider.overrideWithValue(StoreReviewRequester()),
      ],
      child: const WarrantyVaultApp(),
    ),
  );
}

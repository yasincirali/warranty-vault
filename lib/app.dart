import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/ui/brand_mark.dart';
import 'core/ui/cover_observer.dart';
import 'features/items/providers.dart';
import 'features/items/ui/home_screen.dart';
import 'features/settings/settings.dart';
import 'l10n/generated/app_localizations.dart';

class WarrantyVaultApp extends ConsumerWidget {
  const WarrantyVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(settingsProvider.select((s) => s.language));
    final ready = ref.watch(itemViewsProvider.select((v) => v.hasValue));
    return MaterialApp(
      // null follows the phone; a choice in Settings wins over it.
      locale: language == null ? null : Locale(language),
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: [coverObserver],
      // Right after the system splash: the splash comes alive while the
      // cabinet loads (at least one loop), then fades into the home screen.
      builder: (context, child) =>
          BrandIntro(ready: ready, label: AppLocalizations.of(context).loading, child: child!),
      home: const HomeScreen(),
    );
  }
}

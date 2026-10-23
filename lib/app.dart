import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/ui/brand_mark.dart';
import 'core/ui/cover_observer.dart';
import 'features/items/providers.dart';
import 'features/items/ui/home_screen.dart';
import 'features/items/ui/item_detail_screen.dart';
import 'features/reminders/reminders.dart';
import 'features/review/review_prompt.dart';
import 'features/settings/settings.dart';
import 'l10n/generated/app_localizations.dart';

class WarrantyVaultApp extends ConsumerStatefulWidget {
  const WarrantyVaultApp({super.key});

  @override
  ConsumerState<WarrantyVaultApp> createState() => _WarrantyVaultAppState();
}

class _WarrantyVaultAppState extends ConsumerState<WarrantyVaultApp> {
  final _navigator = GlobalKey<NavigatorState>();
  late final AppLifecycleListener _lifecycle;
  StreamSubscription<String>? _taps;
  late final _review = ReviewPrompt(
    store: () => ref.read(settingsStoreProvider),
    requester: () => ref.read(reviewRequesterProvider),
    // Home is the root route; anything pushed on it means "not now".
    atHome: () => !(_navigator.currentState?.canPop() ?? true),
  );

  @override
  void initState() {
    super.initState();
    // Days pass while the app sleeps: coming back re-plans, and the plan's
    // signature check keeps that free when nothing moved.
    _lifecycle = AppLifecycleListener(onResume: () => ref.read(reminderSyncProvider).schedule());
    final scheduler = ref.read(reminderSchedulerProvider);
    _taps = scheduler.taps.listen(_openItem);
    scheduler.launchItem().then((id) {
      if (id != null) _openItem(id);
    }).ignore();
  }

  /// A tapped reminder lands on the product's page, the one that says what
  /// is left and what to do; after the cabinet has loaded.
  Future<void> _openItem(String id) async {
    final view = await ref.read(itemViewProvider(id).future);
    final nav = _navigator.currentState;
    if (view == null || nav == null) return;
    nav.push(MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: id)));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _taps?.cancel();
    _review.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(reminderSyncProvider);
    ref.listen(vaultProvider, (before, after) {
      if (after.value case final v?) _review.onVault(before?.value, v);
    });
    final language = ref.watch(settingsProvider.select((s) => s.language));
    final ready = ref.watch(itemViewsProvider.select((v) => v.hasValue));
    return MaterialApp(
      navigatorKey: _navigator,
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

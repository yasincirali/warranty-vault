import 'dart:async';

import 'package:app_settings/app_settings.dart' as system;
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/format.dart';
import '../../l10n/generated/app_localizations.dart';
import '../items/providers.dart';
import '../settings/settings.dart';
import 'reminder_plan.dart';

/// The platform side of reminders. Everything it receives is already
/// decided ([planReminders]); tests swap in a recording fake.
abstract interface class ReminderScheduler {
  /// Shows the system prompt once; later calls return the stored answer.
  Future<bool> requestPermission();

  /// Whether the phone lets this app's notifications through right now;
  /// null where nothing can tell (tests, web).
  Future<bool?> enabled();

  /// The phone's own notification settings for this app: after a "Don't
  /// allow" the system prompt never comes back, only the user can turn
  /// them on there.
  Future<void> openSettings();

  /// Replaces every pending reminder with [plan].
  Future<void> replace(List<PlannedReminder> plan, AppLocalizations l);

  /// Item id of the reminder that opened the app from a cold start.
  Future<String?> launchItem();

  /// Item ids of reminders tapped while the app runs.
  Stream<String> get taps;
}

class LocalReminderScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<String>.broadcast();
  Future<void>? _ready;

  Future<void> _init() => _ready ??= _plugin
      .initialize(
        settings: const InitializationSettings(
          // Permission is asked in context (after the first product), not
          // at the first launch, so initialisation must not prompt.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (r) {
          final id = r.payload;
          if (id != null && id.isNotEmpty) _taps.add(id);
        },
      )
      .then((_) {});

  @override
  Future<bool> requestPermission() async {
    await _init();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) return await ios.requestPermissions(alert: true, sound: true) ?? false;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<bool?> enabled() async {
    await _init();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) return (await ios.checkPermissions())?.isEnabled;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return android?.areNotificationsEnabled();
  }

  @override
  Future<void> openSettings() => system.AppSettings.openAppSettings(type: system.AppSettingsType.notification);

  @override
  Future<void> replace(List<PlannedReminder> plan, AppLocalizations l) async {
    await _init();
    await _plugin.cancelAll();
    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(),
      android: AndroidNotificationDetails('reminders', 'Reminders', importance: Importance.defaultImportance),
    );
    for (final r in plan) {
      await _plugin.zonedSchedule(
        id: r.id,
        title: r.itemName,
        body: reminderBody(l, r),
        // An absolute instant: the plan is in local time already, and UTC
        // needs no time-zone database (≈400 KB) in the app.
        scheduledDate: tz.TZDateTime.from(r.fireAt.toUtc(), tz.UTC),
        notificationDetails: details,
        // Exact alarms need a special Android permission; a reminder
        // about a date may arrive a few minutes late.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: r.itemId,
      );
    }
  }

  @override
  Future<String?> launchItem() async {
    await _init();
    final d = await _plugin.getNotificationAppLaunchDetails();
    if (d == null || !d.didNotificationLaunchApp) return null;
    return d.notificationResponse?.payload;
  }

  @override
  Stream<String> get taps => _taps.stream;
}

String reminderBody(AppLocalizations l, PlannedReminder r) => switch (r.reason) {
      ReminderReason.ends => l.reminderEndsBody(l.endsIn(kindLabel(l, r.kind), r.daysBefore)),
      ReminderReason.proofShifts => l.reminderProofBody(r.daysBefore),
    };

/// main() overrides this on iOS/Android; tests and the web preview keep
/// a scheduler that does nothing.
final reminderSchedulerProvider = Provider<ReminderScheduler>((_) => NoReminderScheduler());

class NoReminderScheduler implements ReminderScheduler {
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<bool?> enabled() async => null;
  @override
  Future<void> openSettings() async {}
  @override
  Future<void> replace(List<PlannedReminder> plan, AppLocalizations l) async {}
  @override
  Future<String?> launchItem() async => null;
  @override
  Stream<String> get taps => const Stream.empty();
}

/// Keeps the phone's pending reminders equal to the plan. Watched once by
/// the app; reacts to cabinet changes, the Settings switch, the language
/// and the app coming back to the foreground (days pass while it sleeps).
///
/// Cost control: changes are coalesced for [debounce], the plan is pure
/// Dart, and the platform is only called when the plan's signature
/// differs from the last one applied — dragging a product between
/// shelves changes nothing about deadlines and sends nothing.
final reminderSyncProvider = Provider<ReminderSync>((ref) {
  final sync = ReminderSync(ref);
  ref.listen(itemViewsProvider, (_, _) => sync.schedule(), fireImmediately: true);
  ref.listen(settingsProvider, (_, _) => sync.schedule());
  ref.onDispose(sync.dispose);
  return sync;
});

class ReminderSync {
  ReminderSync(this.ref);
  final Ref ref;

  static const debounce = Duration(milliseconds: 800);
  static const _signatureKey = 'reminder_plan';

  Timer? _timer;
  bool _running = false, _again = false;

  void schedule() {
    _timer?.cancel();
    _timer = Timer(debounce, run);
  }

  @visibleForTesting
  Future<void> run() async {
    // One run at a time; a change during a run triggers one more.
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      await _apply();
    } catch (e, s) {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s, library: 'reminders'));
    } finally {
      _running = false;
      if (_again) {
        _again = false;
        schedule();
      }
    }
  }

  Future<void> _apply() async {
    final views = ref.read(itemViewsProvider).value;
    if (views == null) return;
    final settings = ref.read(settingsProvider);
    final store = ref.read(settingsStoreProvider);
    final scheduler = ref.read(reminderSchedulerProvider);
    final plan = settings.reminders ? planReminders(views, ref.read(clockProvider)()) : const <PlannedReminder>[];

    final l = lookupAppLocalizations(_locale(settings.language));
    final signature = '${l.localeName}#${planSignature(plan)}';
    if (store.read(_signatureKey) == signature) return;
    await scheduler.replace(plan, l);
    await store.write(_signatureKey, signature);
  }

  /// The language the notification is written in: the app's, which may
  /// differ from the phone's.
  Locale _locale(String? chosen) {
    final code = chosen ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return Locale(AppLocalizations.supportedLocales.any((x) => x.languageCode == code) ? code : 'en');
  }

  void dispose() => _timer?.cancel();
}

/// Where the phone stands on our notifications, as the screens need it:
/// a reminder that silently never arrives is the one-star review we most
/// want to avoid (Rafım Ar-Ge 24 Oct, yasin "yap").
enum NotificationAccess { notAsked, granted, denied }

/// Set once the system prompt has been shown; the prompt never returns.
const remindersAskedKey = 'reminders_asked';

/// Re-read when the app comes back to the foreground (the user may have
/// just flipped the switch in the phone's settings) and after asking.
final notificationAccessProvider = FutureProvider<NotificationAccess>((ref) async {
  if (ref.watch(settingsStoreProvider).read(remindersAskedKey) == null) return NotificationAccess.notAsked;
  final on = await ref.read(reminderSchedulerProvider).enabled();
  return on == false ? NotificationAccess.denied : NotificationAccess.granted;
});

/// The system prompt, in context: after the user has said yes to our own
/// one-line question (or tapped "Allow" in Settings), never cold.
Future<void> askNotificationPermission(ProviderContainer c) async {
  await c.read(settingsStoreProvider).write(remindersAskedKey, '1');
  await c.read(reminderSchedulerProvider).requestPermission();
  c.invalidate(notificationAccessProvider);
}

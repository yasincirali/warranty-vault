import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Countries the rules file knows, in the order the pickers show them.
const kRegions = ['TR', 'DE', 'EU', 'GB', 'US', 'AU'];

const _eu = {
  'AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'GR', 'HU', 'IE', 'IT', //
  'LV', 'LT', 'LU', 'MT', 'NL', 'PL', 'PT', 'RO', 'SK', 'SI', 'ES', 'SE',
};

/// The country the phone is set to, mapped onto [kRegions]. Read from the
/// device, not from the app language: someone in Germany who prefers the
/// app in English still buys under German law.
String deviceRegion() {
  final l = WidgetsBinding.instance.platformDispatcher.locale;
  final c = l.countryCode?.toUpperCase();
  if (c != null && kRegions.contains(c)) return c;
  if (c != null && _eu.contains(c)) return 'EU';
  return l.languageCode == 'tr' ? 'TR' : 'EU';
}

/// What the user chose in Settings. null = follow the phone.
@immutable
class AppSettings {
  const AppSettings({this.language, this.region, this.reminders = true});

  /// 'tr' / 'en'; null = the phone's language.
  final String? language;

  /// One of [kRegions]; null = the phone's country ([deviceRegion]).
  final String? region;

  /// Local reminders before a right ends. On by default: a reminder is the
  /// reason to keep a warranty app at all (every app compared has one); iOS
  /// still asks for permission, after the first product is saved.
  final bool reminders;

  AppSettings copyWith({String? Function()? language, String? Function()? region, bool? reminders}) => AppSettings(
        language: language == null ? this.language : language(),
        region: region == null ? this.region : region(),
        reminders: reminders ?? this.reminders,
      );
}

/// Where settings live. v1: shared_preferences on the device, read
/// synchronously so the first frame already has the right language.
abstract interface class SettingsStore {
  String? read(String key);
  Future<void> write(String key, String? value);
}

class PrefsSettingsStore implements SettingsStore {
  PrefsSettingsStore(this._prefs);
  final SharedPreferences _prefs;

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String? value) => value == null ? _prefs.remove(key) : _prefs.setString(key, value);
}

/// Tests and the web preview.
class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([Map<String, String>? initial]) : _m = {...?initial};
  final Map<String, String> _m;

  @override
  String? read(String key) => _m[key];

  @override
  Future<void> write(String key, String? value) async => value == null ? _m.remove(key) : _m[key] = value;
}

/// main() overrides this with a [PrefsSettingsStore].
final settingsStoreProvider = Provider<SettingsStore>((_) => MemorySettingsStore());

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  static const _language = 'language', _region = 'region', _reminders = 'reminders';

  SettingsStore get _store => ref.read(settingsStoreProvider);

  @override
  AppSettings build() {
    final store = ref.watch(settingsStoreProvider);
    final lang = store.read(_language);
    final region = store.read(_region);
    // A value from an older or newer build that this one does not know
    // falls back to "follow the phone" instead of breaking the app.
    return AppSettings(
      language: const {'tr', 'en'}.contains(lang) ? lang : null,
      region: kRegions.contains(region) ? region : null,
      reminders: store.read(_reminders) != 'off',
    );
  }

  Future<void> setLanguage(String? code) async {
    state = state.copyWith(language: () => code);
    await _store.write(_language, code);
  }

  Future<void> setRegion(String? region) async {
    state = state.copyWith(region: () => region);
    await _store.write(_region, region);
  }

  Future<void> setReminders(bool on) async {
    state = state.copyWith(reminders: on);
    await _store.write(_reminders, on ? null : 'off');
  }
}

/// The country new products default to.
final defaultRegionProvider = Provider<String>((ref) => ref.watch(settingsProvider).region ?? deviceRegion());

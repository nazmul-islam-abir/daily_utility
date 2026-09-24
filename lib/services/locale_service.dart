import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported app languages. Keep both name (English) and native (Bangla)
/// here so the language switcher can render properly in either locale.
enum AppLanguage {
  bangla('bn', 'বাংলা', 'Bangla'),
  english('en', 'English', 'English');

  final String code;
  final String native;
  final String englishName;
  const AppLanguage(this.code, this.native, this.englishName);

  static AppLanguage fromCode(String? code) {
    if (code == 'bn') return AppLanguage.bangla;
    // Default: English. This is the first-launch experience and also
    // covers any unknown / corrupted value in SharedPreferences.
    return AppLanguage.english;
  }

  Locale get locale => Locale(code);
}

/// Lightweight locale service. Persists the user's pick in
/// SharedPreferences and exposes a [ValueNotifier] so widgets can react
/// when the language changes without rebuilding the whole app.
///
/// Default on first launch: English. The user can switch to Bangla from
/// the language pill in the home header or in Settings.
class LocaleService {
  LocaleService._(this._prefs) {
    final code = _prefs.getString(_key);
    _current = AppLanguage.fromCode(code);
    _notifier = ValueNotifier<Locale>(_current.locale);
  }

  static LocaleService? _instance;
  static const _key = 'app_language';

  final SharedPreferences _prefs;
  late AppLanguage _current;
  late final ValueNotifier<Locale> _notifier;

  ValueNotifier<Locale> get notifier => _notifier;
  AppLanguage get current => _current;
  Locale get locale => _current.locale;

  static Future<LocaleService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final s = LocaleService._(prefs);
    _instance = s;
    return s;
  }

  static LocaleService get instance {
    final i = _instance;
    if (i == null) throw StateError('LocaleService.init() must run first');
    return i;
  }

  Future<void> setLanguage(AppLanguage lang) async {
    _current = lang;
    await _prefs.setString(_key, lang.code);
    _notifier.value = lang.locale;
  }

  static bool get isBangla => instance.current == AppLanguage.bangla;
}

/// Tiny lookup helper: returns the appropriate string for the active
/// language. Takes a [BuildContext] so it reads the locale off the
/// [Localizations] inherited widget — that means any widget that calls
/// `tr(context, ...)` during `build()` will rebuild automatically when
/// the user changes language, without each screen needing its own
/// [ValueListenable] subscription.
///
/// Use [LocaleService.isBangla] (instead) for **detached** strings that
/// have to be built without a context — e.g. local-notification titles
/// and history records scheduled outside the widget tree.
String tr(BuildContext context, String bangla, String english) {
  return Localizations.localeOf(context).languageCode == 'bn' ? bangla : english;
}

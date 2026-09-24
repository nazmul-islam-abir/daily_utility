import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight wrapper around SharedPreferences for app-wide prefs that
/// don't belong in Hive (theme mode, backup flags, signed-in account info,
/// last backup timestamp).
class SettingsService {
  SettingsService._(this._prefs);

  static SettingsService? _instance;
  final SharedPreferences _prefs;

  static Future<SettingsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final s = SettingsService._(prefs);
    _instance = s;
    return s;
  }

  static SettingsService get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('SettingsService.init() must be called before access.');
    }
    return i;
  }

  /// Bumped on every profile-affecting change so widgets can rebuild
  /// without forcing a full SettingsService singleton swap.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static const _kThemeMode = 'theme_mode';
  static const _kBackupEnabled = 'backup_enabled';
  static const _kSignedInEmail = 'signed_in_email';
  static const _kSignedInName = 'signed_in_name';
  static const _kSignedInPhoto = 'signed_in_photo';
  static const _kLastBackupAt = 'last_backup_at';
  static const _kAutoBackup = 'auto_backup';
  static const _kOnboardingComplete = 'onboarding_complete';
  static const _kUserName = 'user_name';
  static const _kProfileBio = 'profile_bio';
  static const _kProfileAvatarPath = 'profile_avatar_path';
  static const _kProfileHomeCityBn = 'profile_home_city_bn';
  static const _kProfileHomeCityEn = 'profile_home_city_en';
  static const _kProfileHomeLat = 'profile_home_lat';
  static const _kProfileHomeLng = 'profile_home_lng';

  ThemeMode get themeMode {
    final v = _prefs.getString(_kThemeMode);
    switch (v) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final v = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_kThemeMode, v);
    _bump();
  }

  bool get backupEnabled => _prefs.getBool(_kBackupEnabled) ?? false;
  Future<void> setBackupEnabled(bool value) => _prefs.setBool(_kBackupEnabled, value);

  bool get autoBackup => _prefs.getBool(_kAutoBackup) ?? true;
  Future<void> setAutoBackup(bool value) => _prefs.setBool(_kAutoBackup, value);

  String? get signedInEmail => _prefs.getString(_kSignedInEmail);
  String? get signedInName => _prefs.getString(_kSignedInName);
  String? get signedInPhoto => _prefs.getString(_kSignedInPhoto);

  Future<void> setSignedInAccount({required String email, String? name, String? photoUrl}) async {
    await _prefs.setString(_kSignedInEmail, email);
    if (name != null) await _prefs.setString(_kSignedInName, name);
    if (photoUrl != null) await _prefs.setString(_kSignedInPhoto, photoUrl);
  }

  Future<void> clearSignedInAccount() async {
    await _prefs.remove(_kSignedInEmail);
    await _prefs.remove(_kSignedInName);
    await _prefs.remove(_kSignedInPhoto);
  }

  DateTime? get lastBackupAt {
    final ms = _prefs.getInt(_kLastBackupAt);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastBackupAt(DateTime time) => _prefs.setInt(_kLastBackupAt, time.millisecondsSinceEpoch);

  Future<void> clearLastBackupAt() => _prefs.remove(_kLastBackupAt);

  bool get onboardingComplete => _prefs.getBool(_kOnboardingComplete) ?? false;
  Future<void> setOnboardingComplete(bool value) => _prefs.setBool(_kOnboardingComplete, value);

  String? get userNameOverride => _prefs.getString(_kUserName);
  Future<void> setUserNameOverride(String? value) async {
    if (value == null || value.isEmpty) {
      await _prefs.remove(_kUserName);
    } else {
      await _prefs.setString(_kUserName, value);
    }
  }

  String get userName {
    final override = userNameOverride;
    if (override != null && override.isNotEmpty) return override;
    return _prefs.getString(_kSignedInName) ?? signedInEmail?.split('@').first ?? 'ব্যবহারকারী';
  }

  // ---------------------------------------------------------------------------
  // Profile (avatar, bio, home city)
  // ---------------------------------------------------------------------------

  String? get bio => _prefs.getString(_kProfileBio);
  Future<void> setBio(String? value) async {
    if (value == null || value.isEmpty) {
      await _prefs.remove(_kProfileBio);
    } else {
      await _prefs.setString(_kProfileBio, value);
    }
    _bump();
  }

  String? get avatarPath => _prefs.getString(_kProfileAvatarPath);
  Future<void> setAvatarPath(String? value) async {
    if (value == null || value.isEmpty) {
      await _prefs.remove(_kProfileAvatarPath);
    } else {
      await _prefs.setString(_kProfileAvatarPath, value);
    }
    _bump();
  }

  String? get homeCityBn => _prefs.getString(_kProfileHomeCityBn);
  String? get homeCityEn => _prefs.getString(_kProfileHomeCityEn);
  double? get homeLat => _prefs.getDouble(_kProfileHomeLat);
  double? get homeLng => _prefs.getDouble(_kProfileHomeLng);

  Future<void> setHomeCity({String? bn, String? en, double? lat, double? lng}) async {
    if (bn == null) {
      await _prefs.remove(_kProfileHomeCityBn);
    } else {
      await _prefs.setString(_kProfileHomeCityBn, bn);
    }
    if (en == null) {
      await _prefs.remove(_kProfileHomeCityEn);
    } else {
      await _prefs.setString(_kProfileHomeCityEn, en);
    }
    if (lat == null) {
      await _prefs.remove(_kProfileHomeLat);
    } else {
      await _prefs.setDouble(_kProfileHomeLat, lat);
    }
    if (lng == null) {
      await _prefs.remove(_kProfileHomeLng);
    } else {
      await _prefs.setDouble(_kProfileHomeLng, lng);
    }
    _bump();
  }

  void _bump() {
    revision.value = revision.value + 1;
  }
}

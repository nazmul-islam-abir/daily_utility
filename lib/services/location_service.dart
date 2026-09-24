import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'locale_service.dart';

/// Why a location request failed. Callers translate this into a friendly,
/// bilingual snackbar using [LocationService.describe].
enum LocationFailure { serviceDisabled, permissionDenied, permissionDeniedForever, timeout, unknown }

/// Shared location helper used by the Prayer screen, the Profile screen,
/// and any future feature that needs a one-shot GPS fix.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// True if the OS-level location switch is on AND we currently have at
  /// least WhenInUse permission. Does not request permission.
  Future<bool> hasUsableLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  /// Requests WhenInUse permission if not yet granted. Returns the final
  /// permission state.
  Future<LocationPermission> ensurePermission() async {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    return p;
  }

  /// Best-effort single GPS fix. On any failure, returns a typed
  /// [LocationFailure] so callers can show a useful snackbar.
  Future<({Position? position, LocationFailure? failure})> getCurrent({
    Duration timeLimit = const Duration(seconds: 12),
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return (position: null, failure: LocationFailure.serviceDisabled);

      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.deniedForever) {
        return (position: null, failure: LocationFailure.permissionDeniedForever);
      }
      if (p == LocationPermission.denied) {
        return (position: null, failure: LocationFailure.permissionDenied);
      }

      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: timeLimit),
        );
        return (position: pos, failure: null);
      } on TimeoutException {
        return (position: null, failure: LocationFailure.timeout);
      } catch (_) {
        return (position: null, failure: LocationFailure.unknown);
      }
    } catch (_) {
      return (position: null, failure: LocationFailure.unknown);
    }
  }

  /// Pushes the user to the OS app-settings page so they can flip the
  /// permission toggle on. Used when permission is permanently denied.
  Future<void> openSettings() => Geolocator.openAppSettings();

  /// Bilingual explanation suitable for a SnackBar.
  static String describe(BuildContext context, LocationFailure f) {
    switch (f) {
      case LocationFailure.serviceDisabled:
        return tr(context, 'লোকেশন সার্ভিস বন্ধ আছে — চালু করে আবার চেষ্টা করুন।', 'Location service is off — turn it on and try again.');
      case LocationFailure.permissionDenied:
        return tr(context, 'লোকেশন অনুমতি দেওয়া হয়নি।', 'Location permission denied.');
      case LocationFailure.permissionDeniedForever:
        return tr(context, 'সেটিংস থেকে লোকেশন অনুমতি দিন।', 'Please allow location from Settings.');
      case LocationFailure.timeout:
        return tr(context, 'লোকেশন পেতে দেরি হচ্ছে — ম্যানুয়াল শহর নির্বাচন করুন।', 'Location is taking too long — please pick a city manually.');
      case LocationFailure.unknown:
        return tr(context, 'অবস্থান পাওয়া যায়নি — ম্যানুয়াল শহর নির্বাচন করুন।', 'Location unavailable — please pick a city manually.');
    }
  }
}

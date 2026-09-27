import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// One submitted contact / support message. Mirrors the `notice`
/// collection's write pattern: app creates documents, admin reads them
/// from the Firebase console.
///
/// Document fields:
///   - name        (string, required) → ContactMessage.name
///   - email       (string, required) → ContactMessage.email
///   - message     (string, required) → ContactMessage.message
///   - createdAt   (Timestamp, server-set) → ContactMessage.createdAt
///   - appVersion  (string, optional)  → ContactMessage.appVersion
///   - platform    (string, optional)  → ContactMessage.platform
///   - locale      (string, optional)  → ContactMessage.locale
class ContactMessage {
  final String name;
  final String email;
  final String message;
  final DateTime createdAt;
  final String? appVersion;
  final String? platform;
  final String? locale;

  const ContactMessage({
    required this.name,
    required this.email,
    required this.message,
    required this.createdAt,
    this.appVersion,
    this.platform,
    this.locale,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        if (appVersion != null) 'appVersion': appVersion,
        if (platform != null) 'platform': platform,
        if (locale != null) 'locale': locale,
      };
}

/// Writes contact-form submissions to the `contact_messages` collection
/// in Firestore. End users can `create`; admin reads from the Firebase
/// console. Mirrors NoticeService's init pattern (double-fallback
/// `_ensureFirebaseInitialized`, ValueNotifiers, debugSummary).
class ContactService {
  ContactService._();
  static final ContactService instance = ContactService._();

  static const String _collection = 'contact_messages';

  final ValueNotifier<bool> configured = ValueNotifier(false);
  final ValueNotifier<bool> submitting = ValueNotifier(false);
  final ValueNotifier<String?> lastError = ValueNotifier(null);

  bool _initialized = false;

  String debugSummary() {
    final buf = StringBuffer();
    buf.writeln('projectId:  ${_projectIdOrUnknown()}');
    buf.writeln('appName:    ${_appNameOrUnknown()}');
    buf.writeln('apps:       ${Firebase.apps.length}');
    buf.writeln('configured: $configured');
    if (lastError.value != null && lastError.value!.isNotEmpty) {
      buf.writeln('lastError:  ${lastError.value}');
    }
    return buf.toString().trimRight();
  }

  String _projectIdOrUnknown() {
    try {
      return Firebase.app().options.projectId;
    } catch (_) {
      return '(not initialised)';
    }
  }

  String _appNameOrUnknown() {
    try {
      return Firebase.app().name;
    } catch (_) {
      return '(not initialised)';
    }
  }

  Future<bool> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isNotEmpty) return true;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('ContactService: initializeApp with options failed ($e), trying default app...');
      }
      try {
        await Firebase.initializeApp();
        return Firebase.apps.isNotEmpty;
      } catch (err) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('ContactService: default initializeApp failed ($err)');
        }
        return false;
      }
    }
  }

  /// Called once at startup or when opening the contact screen.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    configured.value = await _ensureFirebaseInitialized();
  }

  /// Best-effort client-side email validation. Mirrors common conventions;
  /// the server-side validation belongs in Firestore rules if you want to
  /// harden it further.
  static bool isValidEmail(String s) {
    final t = s.trim();
    if (t.isEmpty) return false;
    final re = RegExp(r"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$");
    return re.hasMatch(t);
  }

  /// Submit a contact message. Returns true on success, false otherwise
  /// (and populates [lastError]).
  Future<bool> submit({
    required String name,
    required String email,
    required String message,
    String? appVersion,
    String? platform,
    String? locale,
  }) async {
    submitting.value = true;
    lastError.value = null;

    final isOk = await _ensureFirebaseInitialized();
    configured.value = isOk;

    if (!isOk) {
      lastError.value = 'FIREBASE_NOT_CONFIGURED';
      submitting.value = false;
      return false;
    }

    try {
      final payload = ContactMessage(
        name: name.trim(),
        email: email.trim(),
        message: message.trim(),
        createdAt: DateTime.now(),
        appVersion: appVersion,
        platform: platform,
        locale: locale,
      );
      await FirebaseFirestore.instance.collection(_collection).add(payload.toMap());
      lastError.value = null;
      return true;
    } catch (e, st) {
      lastError.value = e.toString();
      if (kDebugMode) {
        // ignore: avoid_print
        print('ContactService.submit error: $e\n$st');
      }
      return false;
    } finally {
      submitting.value = false;
    }
  }
}

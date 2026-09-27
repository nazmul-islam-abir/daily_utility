import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// A notice / tip / announcement shown to every user, fetched from the
/// `notice` collection in Firestore.
///
/// Document fields:
///   - title    (string, required)  → Notice.title
///   - para     (string, required)  → Notice.body
///   - imgurl   (string, optional)  → Notice.imageUrl
///   - linkurl  (string, optional)  → Notice.linkUrl
///   - createdAt / timestamp (Timestamp, optional) → Notice.createdAt
///   - isPinned / pinned (bool, optional)          → Notice.isPinned
class Notice {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final String? linkUrl;
  final bool isPinned;
  final DateTime createdAt;

  const Notice({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.linkUrl,
    this.isPinned = false,
    required this.createdAt,
  });

  factory Notice.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    bool parsePinned(Map<String, dynamic> m) {
      final v = m['isPinned'] ?? m['pinned'];
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
      return false;
    }

    String? parseString(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    return Notice(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      body: (data['para'] ?? data['body'] ?? '').toString(),
      imageUrl: parseString(data['imgurl'] ?? data['imageUrl']),
      linkUrl: parseString(data['linkurl'] ?? data['linkUrl']),
      isPinned: parsePinned(data),
      createdAt: parseDate(data['createdAt'] ?? data['timestamp']),
    );
  }
}

/// Loads notices from Firestore and exposes a [ValueListenable].
class NoticeService {
  NoticeService._();
  static final NoticeService instance = NoticeService._();

  static const String _collection = 'notice';
  static const int _maxDocs = 100;

  final ValueNotifier<List<Notice>> notices = ValueNotifier(const []);
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> lastError = ValueNotifier(null);
  final ValueNotifier<bool> configured = ValueNotifier(false);

  bool _initialized = false;

  /// Human-readable summary of the current Firestore configuration and
  /// last query result. Used by the Notice Board screen to display a
  /// diagnostic footer under the empty state.
  String debugSummary() {
    final buf = StringBuffer();
    buf.writeln('projectId:  ${_projectIdOrUnknown()}');
    buf.writeln('appName:    ${_appNameOrUnknown()}');
    buf.writeln('apps:       ${Firebase.apps.length}');
    buf.writeln('configured: $configured');
    buf.writeln('docs read:  ${notices.value.length}');
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
        print('NoticeService: initializeApp with options failed ($e), trying default app...');
      }
      try {
        await Firebase.initializeApp();
        return Firebase.apps.isNotEmpty;
      } catch (err) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('NoticeService: default initializeApp failed ($err)');
        }
        return false;
      }
    }
  }

  /// Called once at startup or when opening the notice board.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    configured.value = await _ensureFirebaseInitialized();
    if (configured.value) {
      unawaited(refresh());
    }
  }

  /// Fetch latest notices from the `notice` collection in Firestore.
  /// Performs an UNORDERED `.get()` so the query works even when documents
  /// in the collection don't all have a `createdAt` field (e.g. when the
  /// admin populates data via the test plan without timestamps). Sorting
  /// (pinned first, newest first) is done in-memory afterwards.
  Future<void> refresh() async {
    loading.value = true;
    lastError.value = null;

    final isOk = await _ensureFirebaseInitialized();
    configured.value = isOk;

    if (!isOk) {
      lastError.value = 'FIREBASE_NOT_CONFIGURED';
      loading.value = false;
      return;
    }

    try {
      // Plain, unordered get — no index required, works with any schema.
      final QuerySnapshot<Map<String, dynamic>> snap =
          await FirebaseFirestore.instance
              .collection(_collection)
              .limit(_maxDocs)
              .get();

      final list = snap.docs.map(Notice.fromDoc).toList(growable: false);

      // In-memory sort: pinned first, then by createdAt desc (will be a
      // no-op when all timestamps are the same / fallback-to-now).
      list.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      notices.value = list;
      lastError.value = null; // success — clear any stale error
    } catch (e, st) {
      lastError.value = e.toString();
      if (kDebugMode) {
        // ignore: avoid_print
        print('NoticeService.refresh error: $e\n$st');
      }
    } finally {
      loading.value = false;
    }
  }
}

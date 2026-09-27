import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../models/quiz_category.dart';

/// Diagnostics about the last [QuizService.refresh] call. Surfaced in the
/// hub screen's debug footer so the user can see why a Firestore doc was
/// (or wasn't) turned into a playable quiz category.
class QuizParseReport {
  final int docsRead;
  final int kept;
  final List<QuizDropReason> dropped;
  const QuizParseReport({
    required this.docsRead,
    required this.kept,
    required this.dropped,
  });

  String _humanise() {
    if (docsRead == 0) return 'no docs in `quiz_categories`';
    if (kept == docsRead) return 'all $kept docs accepted';
    final buf = StringBuffer()
      ..writeln('docs read:    $docsRead')
      ..writeln('accepted:     $kept')
      ..writeln('dropped:      ${dropped.length}');
    for (final d in dropped.take(8)) {
      buf.writeln('  - ${d.docId}: ${d.reason}');
    }
    if (dropped.length > 8) buf.writeln('  …and ${dropped.length - 8} more');
    return buf.toString().trimRight();
  }
}

class QuizDropReason {
  final String docId;
  final String reason;
  const QuizDropReason(this.docId, this.reason);
}

/// Loads quiz categories (with their nested question arrays) from the
/// `quiz_categories` collection in Firestore and exposes [ValueNotifier]s
/// for the UI to reactively render.
///
/// Document fields (one document == one category):
///   - name      (string, required)  → QuizCategory.name
///   - subtitle  (string, optional)  → QuizCategory.subtitle
///   - icon      (string, optional)  → key like 'science'/'gk'/'art'
///   - color     (string, optional)  → hex like '0xFF14B8A6' or '#14B8A6'
///   - order     (number, optional)  → ascending sort key
///   - questions (array, required)   → see [QuizQuestion]
///
/// Inside each question:
///   - q        (string)             → question text
///   - options  (array of 4 strings) → answer choices
///   - answer   (int 0-3)            → correct option index
///   - hint     (string, optional)   → shown when the user gets it wrong
class QuizService {
  QuizService._();
  static final QuizService instance = QuizService._();

  static const String _collection = 'quiz_categories';
  static const int _maxDocs = 200;

  final ValueNotifier<List<QuizCategory>> categories = ValueNotifier(const []);
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> lastError = ValueNotifier(null);
  final ValueNotifier<bool> configured = ValueNotifier(false);
  /// Diagnostics — updated every refresh. Shows raw doc count and any
  /// parse/drop reasons so an empty hub can be debugged from the device.
  final ValueNotifier<QuizParseReport> parseReport = ValueNotifier(
    QuizParseReport(docsRead: 0, kept: 0, dropped: const []),
  );

  bool _initialized = false;

  /// Human-readable summary of the current Firestore configuration and
  /// last query result. Mirrors NoticeService.debugSummary() so the UI can
  /// show the same diagnostic footer pattern under the empty state.
  String debugSummary() {
    final buf = StringBuffer();
    buf.writeln('projectId:  ${_projectIdOrUnknown()}');
    buf.writeln('appName:    ${_appNameOrUnknown()}');
    buf.writeln('apps:       ${Firebase.apps.length}');
    buf.writeln('configured: $configured');
    buf.writeln('categories: ${categories.value.length}');
    // Append parse-report so a dropped doc is visible right here.
    final pr = parseReport.value;
    if (pr.docsRead > 0) {
      buf.writeln('');
      buf.writeln(pr._humanise());
    }
    if (lastError.value != null && lastError.value!.isNotEmpty) {
      buf.writeln('');
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
        print('QuizService: initializeApp with options failed ($e), trying default app...');
      }
      try {
        await Firebase.initializeApp();
        return Firebase.apps.isNotEmpty;
      } catch (err) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('QuizService: default initializeApp failed ($err)');
        }
        return false;
      }
    }
  }

  /// Called once at startup or when opening the quiz hub.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    configured.value = await _ensureFirebaseInitialized();
    if (configured.value) {
      unawaited(refresh());
    }
  }

  /// Fetch all categories from the `quiz_categories` collection. Performs
  /// an UNORDERED `.get()` so the query works without a composite index
  /// (categories might not have an `order` field). Categories whose
  /// `questions` array is empty (or all entries are malformed) are dropped.
  /// The remaining list is sorted by `order` asc, then by `name` asc.
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
      final QuerySnapshot<Map<String, dynamic>> snap =
          await FirebaseFirestore.instance
              .collection(_collection)
              .limit(_maxDocs)
              .get();

      final kept = <QuizCategory>[];
      final dropped = <QuizDropReason>[];
      for (final doc in snap.docs) {
        try {
          final cat = QuizCategory.fromDoc(doc);
          // Show every doc that has a name, even if no questions are valid,
          // so the user can SEE the doc is there and fix the schema. The
          // playableCount guard is moved into the quiz-playing code path.
          if (cat.name.trim().isEmpty) {
            dropped.add(QuizDropReason(doc.id, 'missing `name` field'));
            continue;
          }
          kept.add(cat);
        } catch (e) {
          dropped.add(QuizDropReason(doc.id, 'parse error: $e'));
        }
      }

      // In-memory sort: order asc, then name asc.
      kept.sort((a, b) {
        final cmp = a.order.compareTo(b.order);
        if (cmp != 0) return cmp;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      categories.value = kept;
      parseReport.value = QuizParseReport(
        docsRead: snap.docs.length,
        kept: kept.length,
        dropped: dropped,
      );
      lastError.value = null; // success — clear any stale error
      if (kDebugMode) {
        // ignore: avoid_print
        print('QuizService.refresh: docs=${snap.docs.length} kept=${kept.length} '
            'dropped=${dropped.length}');
        for (final d in dropped) {
          // ignore: avoid_print
          print('  - ${d.docId}: ${d.reason}');
        }
      }
    } catch (e, st) {
      lastError.value = e.toString();
      if (kDebugMode) {
        // ignore: avoid_print
        print('QuizService.refresh error: $e\n$st');
      }
    } finally {
      loading.value = false;
    }
  }
}

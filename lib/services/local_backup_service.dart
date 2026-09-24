import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../models/baki_khata.dart';
import '../models/habit.dart';
import '../models/history_entry.dart';
import '../models/loan.dart';
import '../models/mood_entry.dart';
import '../models/note.dart';
import '../models/post.dart';
import '../models/quiz_result.dart';
import '../models/shopping_item.dart';
import '../models/subscription.dart';
import '../models/todo_item.dart';
import '../models/transaction.dart';
import '../models/vault_credential.dart';
import 'data_refresh_service.dart';
import 'hive_service.dart';

enum LocalBackupStatus { success, error, cancelled }

class LocalBackupResult {
  final LocalBackupStatus status;
  final String? message;
  final int? recordsRestored;
  final String? filePath;

  LocalBackupResult(this.status, {this.message, this.recordsRestored, this.filePath});
}

/// File-based backup. The user exports a `.json` file (which they can email
/// to themselves, save in their own cloud, AirDrop, etc.) and imports it
/// on another device. No Google account, no verification, no Cloud Console.
///
/// The on-disk JSON shape is identical to the legacy Google Drive backup
/// so existing exports continue to work.
class LocalBackupService {
  LocalBackupService._();
  static final LocalBackupService instance = LocalBackupService._();

  static const _filePrefix = 'daily_utility_backup';

  static const _uuid = Uuid();

  /// Build the JSON payload in memory.
  Map<String, dynamic> _exportPayload() {
    return {
      'version': 3,
      'exportedAt': DateTime.now().toIso8601String(),
      'boxes': {
        'todos': HiveService.todos.values.map(_todoToJson).toList(),
        'notes': HiveService.notes.values.map(_noteToJson).toList(),
        'transactions': HiveService.transactions.values.map(_txToJson).toList(),
        'baki_people': HiveService.people.values.map(_personToJson).toList(),
        'baki_ledger': HiveService.ledger.values.map(_ledgerToJson).toList(),
        'loans': HiveService.loans.values.map(_loanToJson).toList(),
        'shopping': HiveService.shopping.values.map(_shoppingToJson).toList(),
        'history': HiveService.history.values.map(_historyToJson).toList(),
        'habits': HiveService.habits.values.map(_habitToJson).toList(),
        'moods': HiveService.moods.values.map(_moodToJson).toList(),
        'vault': HiveService.vault.values.map(_vaultToJson).toList(),
        'quiz_results': HiveService.quizResults.values.map(_quizToJson).toList(),
        'subscriptions': HiveService.subscriptions.values.map(_subscriptionToJson).toList(),
        'posts': HiveService.posts.values.map(_postToJson).toList(),
        'habit_checks': HiveService.habitChecks.keys
            .map((k) => {'key': k.toString(), 'value': HiveService.habitChecks.get(k) as bool})
            .toList(),
      },
    };
  }

  /// Read the file at [path] and return its bytes as a base64 string.
  /// Returns null if the file is missing or too large to embed (>5 MB
  /// per image keeps the JSON share-friendly).
  String? _readImageAsBase64(String path) {
    try {
      final f = File(path);
      if (!f.existsSync()) return null;
      final bytes = f.readAsBytesSync();
      if (bytes.length > 5 * 1024 * 1024) return null;
      return base64Encode(bytes);
    } catch (_) {
      return null;
    }
  }

  /// Decode a base64 image blob and write it to the app documents directory
  /// under `posts/<uuid>.<ext>`. Returns the new file path, or null on
  /// failure.
  Future<String?> _writeImageFromBase64(String? b64, String ext) async {
    if (b64 == null || b64.isEmpty) return null;
    try {
      final bytes = base64Decode(b64);
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/posts');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final dest = File('${dir.path}/${_uuid.v4()}.$ext');
      await dest.writeAsBytes(bytes, flush: true);
      return dest.path;
    } catch (_) {
      return null;
    }
  }

  String _extFromPath(String path) {
    final i = path.lastIndexOf('.');
    if (i < 0 || i == path.length - 1) return 'jpg';
    return path.substring(i + 1).toLowerCase();
  }

  /// Writes the payload to a temp file and opens the OS share sheet so the
  /// user can save it to Downloads, send it via WhatsApp / email, upload it
  /// to their own Drive / Dropbox, etc.
  Future<LocalBackupResult> exportAndShare({String? shareText}) async {
    try {
      final payload = _exportPayload();
      final bytes = utf8.encode(jsonEncode(payload));

      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final file = File('${dir.path}/${_filePrefix}_$stamp.json');
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json', name: '${_filePrefix}_$stamp.json')],
        text: shareText ?? 'Daily Utility backup',
      );

      final records = (payload['boxes'] as Map).values.fold<int>(0, (acc, v) => acc + (v as List).length);
      return LocalBackupResult(
        LocalBackupStatus.success,
        message: 'ব্যাকআপ তৈরি হয়েছে — ফাইলটি শেয়ার/সেভ করুন',
        recordsRestored: records,
        filePath: file.path,
      );
    } catch (e) {
      return LocalBackupResult(LocalBackupStatus.error, message: 'রপ্তানি ব্যর্থ: $e');
    }
  }

  /// Opens the system file picker and imports the chosen JSON.
  Future<LocalBackupResult> pickAndImport() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) {
        return LocalBackupResult(LocalBackupStatus.cancelled, message: 'আমদানি বাতিল');
      }
      final file = picked.files.single;

      final Uint8List bytes;
      if (file.bytes != null) {
        bytes = file.bytes!;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      } else {
        return LocalBackupResult(LocalBackupStatus.error, message: 'ফাইল পড়া যায়নি');
      }

      final payload = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      if (payload['boxes'] is! Map) {
        return LocalBackupResult(LocalBackupStatus.error, message: 'ফাইলটি সঠিক ব্যাকআপ ফরম্যাটে নয়');
      }

      final count = await _restorePayload(payload);
      return LocalBackupResult(
        LocalBackupStatus.success,
        message: '$count টি রেকর্ড রিস্টোর হয়েছে',
        recordsRestored: count,
        filePath: file.name,
      );
    } catch (e) {
      return LocalBackupResult(LocalBackupStatus.error, message: 'আমদানি ব্যর্থ: $e');
    }
  }

  /// Restore from a raw byte buffer (used by tests / future flows).
  Future<LocalBackupResult> importBytes(List<int> raw) async {
    try {
      final payload = jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
      if (payload['boxes'] is! Map) {
        return LocalBackupResult(LocalBackupStatus.error, message: 'ফাইলটি সঠিক ব্যাকআপ ফরম্যাটে নয়');
      }
      final count = await _restorePayload(payload);
      return LocalBackupResult(LocalBackupStatus.success, message: '$count টি রেকর্ড রিস্টোর হয়েছে', recordsRestored: count);
    } catch (e) {
      return LocalBackupResult(LocalBackupStatus.error, message: 'আমদানি ব্যর্থ: $e');
    }
  }

  Future<int> _restorePayload(Map<String, dynamic> payload) async {
    final boxes = payload['boxes'] as Map<String, dynamic>;
    int total = 0;

    void putAll<T>(String key, Box<T> box, T Function(Map<String, dynamic>) parse, String Function(T) idOf) {
      if (!boxes.containsKey(key)) return;
      final list = (boxes[key] as List).cast<Map<String, dynamic>>();
      box.clear();
      for (final raw in list) {
        final obj = parse(raw);
        box.put(idOf(obj), obj);
        total++;
      }
    }

    putAll('todos', HiveService.todos, _todoFromJson, (t) => t.id);
    putAll('notes', HiveService.notes, _noteFromJson, (n) => n.id);
    putAll('transactions', HiveService.transactions, _txFromJson, (t) => t.id);
    putAll('baki_people', HiveService.people, _personFromJson, (p) => p.id);
    putAll('baki_ledger', HiveService.ledger, _ledgerFromJson, (l) => l.id);
    putAll('loans', HiveService.loans, _loanFromJson, (l) => l.id);
    putAll('shopping', HiveService.shopping, _shoppingFromJson, (s) => s.id);
    putAll('history', HiveService.history, _historyFromJson, (h) => h.id);
    putAll('habits', HiveService.habits, _habitFromJson, (h) => h.id);
    putAll('moods', HiveService.moods, _moodFromJson, (m) => m.id);
    putAll('vault', HiveService.vault, _vaultFromJson, (v) => v.id);
    putAll('quiz_results', HiveService.quizResults, _quizFromJson, (r) => r.id);
    putAll('subscriptions', HiveService.subscriptions, _subscriptionFromJson, (s) => s.id);

    // Posts are handled specially — image blobs need to be written to the
    // app docs dir first, then the post is saved with the new paths.
    if (boxes.containsKey('posts')) {
      final list = (boxes['posts'] as List).cast<Map<String, dynamic>>();
      HiveService.posts.clear();
      for (final raw in list) {
        final post = _postFromJson(raw);
        final images = (raw['images'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
        if (images.isNotEmpty) {
          final restoredPaths = <String>[];
          for (final img in images) {
            final ext = (img['ext'] as String?) ?? 'jpg';
            final path = await _writeImageFromBase64(img['data'] as String?, ext);
            if (path != null) restoredPaths.add(path);
          }
          post.imagePaths = restoredPaths;
        }
        HiveService.posts.put(post.id, post);
        total++;
      }
    }

    if (boxes.containsKey('habit_checks')) {
      final list = (boxes['habit_checks'] as List).cast<Map<String, dynamic>>();
      HiveService.habitChecks.clear();
      for (final raw in list) {
        HiveService.habitChecks.put(raw['key'] as String, raw['value'] as bool);
        total++;
      }
    }

    // Wholesale replacement of all boxes — notify every listener that the
    // dataset version changed so screens can rebuild even if they were
    // mounted before the restore happened.
    DataRefreshService.instance.bump();

    // Flush every box to disk immediately so the data survives an app
    // kill before Hive's periodic auto-flush kicks in. Without this the
    // user can restore, see "35 records restored", kill the app, and
    // find everything empty on next launch.
    await _flushAll();
    return total;
  }

  Future<void> _flushAll() async {
    final boxes = <Box>[
      HiveService.todos,
      HiveService.notes,
      HiveService.transactions,
      HiveService.people,
      HiveService.ledger,
      HiveService.loans,
      HiveService.shopping,
      HiveService.history,
      HiveService.habits,
      HiveService.habitChecks,
      HiveService.moods,
      HiveService.vault,
      HiveService.quizResults,
      HiveService.subscriptions,
      HiveService.posts,
    ];
    for (final b in boxes) {
      try {
        await b.flush();
      } catch (_) {}
    }
  }

  Map<String, dynamic> _todoToJson(TodoItem t) => {
        'id': t.id,
        'title': t.title,
        'notes': t.notes,
        'priority': t.priority,
        'dueAt': t.dueAt?.toIso8601String(),
        'reminderMinutesBefore': t.reminderMinutesBefore,
        'recurrence': t.recurrence,
        'isCompleted': t.isCompleted,
        'completedAt': t.completedAt?.toIso8601String(),
        'createdAt': t.createdAt.toIso8601String(),
      };

  TodoItem _todoFromJson(Map<String, dynamic> j) => TodoItem(
        id: j['id'] as String,
        title: j['title'] as String,
        notes: j['notes'] as String?,
        priority: j['priority'] as String? ?? 'medium',
        dueAt: j['dueAt'] == null ? null : DateTime.parse(j['dueAt'] as String),
        reminderMinutesBefore: j['reminderMinutesBefore'] as int?,
        recurrence: j['recurrence'] as String? ?? 'none',
        isCompleted: j['isCompleted'] as bool? ?? false,
        completedAt: j['completedAt'] == null ? null : DateTime.parse(j['completedAt'] as String),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  Map<String, dynamic> _noteToJson(Note n) => {
        'id': n.id,
        'title': n.title,
        'body': n.body,
        'type': n.type,
        'checklist': n.checklistItems
            .map((c) => {'id': c.id, 'text': c.text, 'checked': c.checked})
            .toList(),
        'isPinned': n.isPinned,
        'isSticky': n.isSticky,
        'colorValue': n.colorValue,
        'createdAt': n.createdAt.toIso8601String(),
        'updatedAt': n.updatedAt.toIso8601String(),
      };

  Note _noteFromJson(Map<String, dynamic> j) {
    final cl = ((j['checklist'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map((c) => ChecklistItem(id: c['id'] as String, text: c['text'] as String, checked: c['checked'] as bool? ?? false))
        .toList();
    return Note(
      id: j['id'] as String,
      title: j['title'] as String,
      body: j['body'] as String? ?? '',
      type: j['type'] as String? ?? 'text',
      checklistItems: cl,
      isPinned: j['isPinned'] as bool? ?? false,
      isSticky: j['isSticky'] as bool? ?? false,
      colorValue: j['colorValue'] as int? ?? 0xFFF2A93B,
      createdAt: DateTime.parse(j['createdAt'] as String),
      updatedAt: DateTime.parse(j['updatedAt'] as String),
    );
  }

  Map<String, dynamic> _txToJson(MoneyTransaction t) => {
        'id': t.id,
        'amount': t.amount,
        'type': t.type,
        'category': t.category,
        'note': t.note,
        'date': t.date.toIso8601String(),
        'createdAt': t.createdAt.toIso8601String(),
      };

  MoneyTransaction _txFromJson(Map<String, dynamic> j) => MoneyTransaction(
        id: j['id'] as String,
        amount: (j['amount'] as num).toDouble(),
        type: j['type'] as String,
        category: j['category'] as String,
        note: j['note'] as String?,
        date: DateTime.parse(j['date'] as String),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  Map<String, dynamic> _personToJson(Person p) => {
        'id': p.id,
        'name': p.name,
        'phone': p.phone,
        'createdAt': p.createdAt.toIso8601String(),
      };

  Person _personFromJson(Map<String, dynamic> j) => Person(
        id: j['id'] as String,
        name: j['name'] as String,
        phone: j['phone'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  Map<String, dynamic> _ledgerToJson(LedgerEntry l) => {
        'id': l.id,
        'personId': l.personId,
        'amount': l.amount,
        'direction': l.direction,
        'note': l.note,
        'date': l.date.toIso8601String(),
      };

  LedgerEntry _ledgerFromJson(Map<String, dynamic> j) => LedgerEntry(
        id: j['id'] as String,
        personId: j['personId'] as String,
        amount: (j['amount'] as num).toDouble(),
        direction: j['direction'] as String,
        note: j['note'] as String?,
        date: DateTime.parse(j['date'] as String),
      );

  Map<String, dynamic> _loanToJson(Loan l) => {
        'id': l.id,
        'title': l.title,
        'principal': l.principal,
        'interestRatePercent': l.interestRatePercent,
        'monthlyPayment': l.monthlyPayment,
        'startDate': l.startDate.toIso8601String(),
        'termMonths': l.termMonths,
        'nextPaymentDate': l.nextPaymentDate?.toIso8601String(),
        'reminderMinutesBefore': l.reminderMinutesBefore,
        'payments': l.payments
            .map((p) => {'id': p.id, 'amount': p.amount, 'date': p.date.toIso8601String(), 'note': p.note})
            .toList(),
        'createdAt': l.createdAt.toIso8601String(),
      };

  Loan _loanFromJson(Map<String, dynamic> j) => Loan(
        id: j['id'] as String,
        title: j['title'] as String,
        principal: (j['principal'] as num).toDouble(),
        interestRatePercent: (j['interestRatePercent'] as num).toDouble(),
        monthlyPayment: (j['monthlyPayment'] as num).toDouble(),
        startDate: DateTime.parse(j['startDate'] as String),
        termMonths: j['termMonths'] as int?,
        nextPaymentDate: j['nextPaymentDate'] == null ? null : DateTime.parse(j['nextPaymentDate'] as String),
        reminderMinutesBefore: j['reminderMinutesBefore'] as int?,
        payments: ((j['payments'] as List?) ?? [])
            .cast<Map<String, dynamic>>()
            .map((p) => LoanPayment(
                  id: p['id'] as String,
                  amount: (p['amount'] as num).toDouble(),
                  date: DateTime.parse(p['date'] as String),
                  note: p['note'] as String?,
                ))
            .toList(),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  Map<String, dynamic> _shoppingToJson(ShoppingItem s) => {
        'id': s.id,
        'name': s.name,
        'quantity': s.quantity,
        'checked': s.checked,
        'createdAt': s.createdAt.toIso8601String(),
      };

  ShoppingItem _shoppingFromJson(Map<String, dynamic> j) => ShoppingItem(
        id: j['id'] as String,
        name: j['name'] as String,
        quantity: j['quantity'] as String?,
        checked: j['checked'] as bool? ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  Map<String, dynamic> _historyToJson(HistoryEntry h) => {
        'id': h.id,
        'kind': h.kind,
        'title': h.title,
        'subtitle': h.subtitle,
        'result': h.result,
        'inputs': h.inputs,
        'createdAt': h.createdAt.toIso8601String(),
      };

  HistoryEntry _historyFromJson(Map<String, dynamic> j) => HistoryEntry(
        id: j['id'] as String,
        kind: j['kind'] as String,
        title: j['title'] as String,
        subtitle: j['subtitle'] as String? ?? '',
        result: j['result'] as String,
        inputs: ((j['inputs'] as Map?) ?? {}).map((k, v) => MapEntry(k.toString(), v.toString())),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  Map<String, dynamic> _habitToJson(Habit h) => {
        'id': h.id,
        'title': h.title,
        'subtitle': h.subtitle,
        'iconCodePoint': h.iconCodePoint,
        'colorValue': h.colorValue,
        'recurrence': h.recurrence,
        'daysOfWeek': h.daysOfWeek,
        'createdAt': h.createdAt.toIso8601String(),
      };

  Habit _habitFromJson(Map<String, dynamic> j) => Habit(
        id: j['id'] as String,
        title: j['title'] as String,
        subtitle: (j['subtitle'] as String?) ?? '',
        iconCodePoint: j['iconCodePoint'] as int,
        colorValue: j['colorValue'] as int,
        recurrence: (j['recurrence'] as String?) ?? 'daily',
        daysOfWeek: ((j['daysOfWeek'] as List?) ?? const [1, 2, 3, 4, 5, 6, 7]).cast<int>(),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  Map<String, dynamic> _moodToJson(MoodEntry m) => {
        'id': m.id,
        'date': m.date.toIso8601String(),
        'moodLevel': m.moodLevel,
        'prompt': m.prompt,
        'body': m.body,
        'createdAt': m.createdAt.toIso8601String(),
      };

  MoodEntry _moodFromJson(Map<String, dynamic> j) => MoodEntry(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        moodLevel: j['moodLevel'] as int,
        prompt: (j['prompt'] as String?) ?? '',
        body: (j['body'] as String?) ?? '',
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  Map<String, dynamic> _vaultToJson(VaultCredential v) => {
        'id': v.id,
        'title': v.title,
        'username': v.username,
        'password': v.password,
        'url': v.url,
        'category': v.category,
        'iconCodePoint': v.iconCodePoint,
        'colorValue': v.colorValue,
        'createdAt': v.createdAt.toIso8601String(),
      };

  VaultCredential _vaultFromJson(Map<String, dynamic> j) => VaultCredential(
        id: j['id'] as String,
        title: j['title'] as String,
        username: j['username'] as String,
        password: j['password'] as String,
        url: j['url'] as String?,
        category: (j['category'] as String?) ?? 'other',
        iconCodePoint: j['iconCodePoint'] as int,
        colorValue: j['colorValue'] as int,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  Map<String, dynamic> _quizToJson(QuizResult r) => {
        'id': r.id,
        'score': r.score,
        'correctCount': r.correctCount,
        'totalQuestions': r.totalQuestions,
        'completedAt': r.completedAt.toIso8601String(),
      };

  QuizResult _quizFromJson(Map<String, dynamic> j) => QuizResult(
        id: j['id'] as String,
        score: j['score'] as int,
        correctCount: j['correctCount'] as int,
        totalQuestions: j['totalQuestions'] as int,
        completedAt: DateTime.parse(j['completedAt'] as String),
      );

  Map<String, dynamic> _postToJson(Post p) {
    // Embed image bytes (base64) so the backup is fully self-contained —
    // restore on any device rebuilds the originals in the app docs dir.
    final images = <Map<String, dynamic>>[];
    for (final path in p.imagePaths) {
      final b64 = _readImageAsBase64(path);
      if (b64 != null) {
        images.add({'ext': _extFromPath(path), 'data': b64});
      }
    }
    return {
      'id': p.id,
      'title': p.title,
      'body': p.body,
      'category': postCategoryKey(p.category),
      'tags': p.tags,
      'colorValue': p.colorValue,
      'images': images,
      'pinned': p.pinned,
      'liked': p.liked,
      'likes': p.likes,
      'comments': p.comments,
      'impressions': p.impressions,
      'authorName': p.authorName,
      'authorAvatarPath': p.authorAvatarPath,
      'createdAt': p.createdAt.toIso8601String(),
      'updatedAt': p.updatedAt.toIso8601String(),
    };
  }

  Post _postFromJson(Map<String, dynamic> j) => Post(
        id: j['id'] as String,
        title: j['title'] as String,
        body: (j['body'] as String?) ?? '',
        category: postCategoryFromKey(j['category'] as String?),
        tags: ((j['tags'] as List?) ?? const []).cast<String>(),
        colorValue: (j['colorValue'] as int?) ?? 0xFFE11D48,
        imagePaths: const <String>[],
        pinned: (j['pinned'] as bool?) ?? false,
        liked: (j['liked'] as bool?) ?? false,
        likes: (j['likes'] as int?) ?? 0,
        comments: (j['comments'] as int?) ?? 0,
        impressions: (j['impressions'] as int?) ?? 0,
        authorName: j['authorName'] as String?,
        authorAvatarPath: j['authorAvatarPath'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );

  Map<String, dynamic> _subscriptionToJson(Subscription s) => {
        'id': s.id,
        'title': s.title,
        'amount': s.amount,
        'currency': s.currency,
        'cycle': s.cycle.name,
        'category': s.category,
        'nextRenewalDate': s.nextRenewalDate.toIso8601String(),
        'notes': s.notes,
        'colorValue': s.colorValue,
        'isActive': s.isActive,
        'reminderDaysBefore': s.reminderDaysBefore,
        'notificationId': s.notificationId,
        'createdAt': s.createdAt.toIso8601String(),
      };

  Subscription _subscriptionFromJson(Map<String, dynamic> j) {
    final cycleKey = (j['cycle'] as String?) ?? (j['billingCycle'] as String?) ?? 'monthly';
    BillingCycle parsedCycle;
    try {
      parsedCycle = BillingCycle.values.firstWhere((c) => c.name == cycleKey);
    } catch (_) {
      parsedCycle = BillingCycle.monthly;
    }
    return Subscription(
      id: j['id'] as String,
      title: j['title'] as String,
      amount: (j['amount'] as num).toDouble(),
      currency: (j['currency'] as String?) ?? 'BDT',
      cycle: parsedCycle,
      category: (j['category'] as String?) ?? 'other',
      nextRenewalDate: DateTime.parse((j['nextRenewalDate'] ?? j['nextBillingDate']) as String),
      notes: j['notes'] as String?,
      colorValue: (j['colorValue'] as int?) ?? 0xFFEC4899,
      isActive: (j['isActive'] as bool?) ?? true,
      reminderDaysBefore: j['reminderDaysBefore'] as int?,
      notificationId: j['notificationId'] as int?,
      createdAt: DateTime.parse(j['createdAt'] as String),
    );
  }
}

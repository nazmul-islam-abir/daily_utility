import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// One quiz question loaded from Firestore. The shape stored in
/// `quiz_categories/{id}.questions[]` is:
///
/// ```json
/// {
///   "q":        "Question text",
///   "options":  ["A", "B", "C", "D"],
///   "answer":   1,            // 0-based index of the correct option
///   "hint":     "Optional"
/// }
/// ```
class QuizQuestion {
  final String q;
  final List<String> options;
  final int correctIndex;
  final String? hint;

  const QuizQuestion({
    required this.q,
    required this.options,
    required this.correctIndex,
    this.hint,
  });
}

/// One quiz category — a document in the `quiz_categories` collection.
/// Its `questions` array contains all the questions for that category.
class QuizCategory {
  final String id;
  final String name;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final double order;
  final List<QuizQuestion> questions;

  const QuizCategory({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.order,
    required this.questions,
  });

  /// Number of questions that will actually be played (questions whose
  /// `options` length is exactly 4 and `correctIndex` is in range).
  int get playableCount => questions.length;

  factory QuizCategory.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (kDebugMode) {
      // ignore: avoid_print
      print('QuizCategory.fromDoc id=${doc.id} keys=${data.keys.toList()} '
          'questions=${(data['questions'] as List?)?.length ?? "null"} '
          'name=${data['name']}');
    }

    String parseString(dynamic v, {String fallback = ''}) {
      if (v == null) return fallback;
      final s = v.toString().trim();
      return s.isEmpty ? fallback : s;
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    Color? parseColor(dynamic v) {
      if (v == null) return null;
      final raw = v.toString().trim();
      if (raw.isEmpty) return null;
      var s = raw.startsWith('0x') ? raw.substring(2) : raw;
      if (s.startsWith('#')) s = s.substring(1);
      if (s.length == 8) s = s.substring(2); // strip alpha
      if (s.length != 6) return null;
      final val = int.tryParse(s, radix: 16);
      if (val == null) return null;
      return Color(0xFF000000 | val);
    }

    final rawQuestions = (data['questions'] as List?) ?? const [];
    final qs = <QuizQuestion>[];
    for (final raw in rawQuestions) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final opts = (m['options'] as List?) ?? const [];
      if (opts.length != 4) continue;
      final ans = parseInt(m['answer']);
      if (ans == null || ans < 0 || ans > 3) continue;
      final q = parseString(m['q'] ?? m['question']);
      if (q.isEmpty) continue;
      qs.add(
        QuizQuestion(
          q: q,
          options: opts.map((e) => e.toString()).toList(growable: false),
          correctIndex: ans,
          hint: m['hint']?.toString(),
        ),
      );
    }

    final subtitle = (() {
      final s = parseString(data['subtitle'] ?? data['desc']);
      return s.isEmpty ? null : s;
    })();

    return QuizCategory(
      id: parseString(data['id'], fallback: doc.id),
      name: parseString(data['name'] ?? data['title']),
      subtitle: subtitle,
      icon: quizIconFromKey(parseString(data['icon'])),
      color: parseColor(data['color']) ?? AppColors.quiz,
      order: parseDouble(data['order'] ?? data['orderIndex']) ?? double.infinity,
      questions: qs,
    );
  }
}

/// Map a friendly icon key from Firestore to a real [IconData]. Falls back
/// to the brand brain icon if the key is unknown.
IconData quizIconFromKey(String key) {
  switch (key.toLowerCase()) {
    case 'science':
    case 'phy':
    case 'physics':
      return Icons.science_outlined;
    case 'chem':
    case 'chemistry':
      return Icons.biotech_outlined;
    case 'bio':
    case 'biology':
      return Icons.eco_outlined;
    case 'math':
    case 'maths':
      return Icons.calculate_outlined;
    case 'history':
      return Icons.history_edu_outlined;
    case 'geography':
    case 'geo':
      return Icons.public_outlined;
    case 'gk':
    case 'general':
      return Icons.psychology_outlined;
    case 'art':
      return Icons.palette_outlined;
    case 'language':
    case 'lang':
      return Icons.translate_outlined;
    case 'sports':
      return Icons.sports_soccer_outlined;
    case 'music':
      return Icons.music_note_outlined;
    case 'movies':
    case 'film':
      return Icons.movie_outlined;
    case 'tech':
    case 'technology':
      return Icons.memory_outlined;
    default:
      return Icons.psychology_outlined;
  }
}

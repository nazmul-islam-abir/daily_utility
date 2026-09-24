import '../models/habit.dart';
import 'hive_service.dart';

/// Streak / consistency math for habits. All values are computed on
/// demand from the `habit_checks` box.
class HabitService {
  HabitService._();

  static bool isChecked(Habit h, DateTime date) {
    return HiveService.habitChecks.get(HabitCheck.key(h.id, date)) == true;
  }

  static Future<void> setChecked(Habit h, DateTime date, bool value) async {
    await HiveService.habitChecks.put(HabitCheck.key(h.id, date), value);
  }

  /// Number of consecutive days (ending today) where the habit was checked.
  /// For weekly habits, count consecutive weeks (Mon..Sun) with all expected
  /// days checked.
  static int currentStreak(Habit h, {DateTime? today}) {
    final t = today ?? DateTime.now();
    int streak = 0;
    if (h.recurrence == 'weekly') {
      for (int week = 0; week < 52; week++) {
        final weekStart = t.subtract(Duration(days: t.weekday - 1 + week * 7));
        final days = h.daysOfWeek;
        bool all = true;
        bool any = false;
        for (final dow in days) {
          final d = weekStart.add(Duration(days: dow - 1));
          if (d.isAfter(t)) continue;
          any = true;
          if (!isChecked(h, d)) {
            all = false;
            break;
          }
        }
        if (all && any) {
          streak++;
        } else {
          break;
        }
      }
    } else {
      for (int i = 0; i < 365; i++) {
        final d = DateTime(t.year, t.month, t.day).subtract(Duration(days: i));
        if (isChecked(h, d)) {
          streak++;
        } else {
          if (i == 0) continue;
          break;
        }
      }
    }
    return streak;
  }

  /// Consistency percentage over the last 30 days for this habit.
  static int consistency(Habit h, {DateTime? today}) {
    final t = today ?? DateTime.now();
    int expected = 0;
    int done = 0;
    for (int i = 0; i < 30; i++) {
      final d = DateTime(t.year, t.month, t.day).subtract(Duration(days: i));
      bool applies = true;
      if (h.recurrence == 'weekly') {
        applies = h.daysOfWeek.contains(d.weekday);
      }
      if (!applies) continue;
      expected++;
      if (isChecked(h, d)) done++;
    }
    if (expected == 0) return 0;
    return ((done / expected) * 100).round();
  }

  /// Whether this habit is "due" today.
  static bool isDueToday(Habit h, {DateTime? today}) {
    final t = today ?? DateTime.now();
    if (h.recurrence == 'daily') return true;
    return h.daysOfWeek.contains(t.weekday);
  }

  /// Total checks across all habits in the last 30 days.
  static int totalChecksLast30(List<Habit> habits, {DateTime? today}) {
    final t = today ?? DateTime.now();
    int total = 0;
    for (final h in habits) {
      for (int i = 0; i < 30; i++) {
        final d = DateTime(t.year, t.month, t.day).subtract(Duration(days: i));
        if (h.recurrence == 'weekly' && !h.daysOfWeek.contains(d.weekday)) continue;
        if (isChecked(h, d)) total++;
      }
    }
    return total;
  }
}

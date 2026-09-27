import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/habit.dart';
import '../models/mood_entry.dart';
import '../services/habit_service.dart';
import '../services/hive_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';
import '../screens/habits/habits_screen.dart';
import '../screens/mood/mood_screen.dart';

const _uuid = Uuid();

/// Dashboard "mood + habit" sliders — two compact cards at the top of the
/// home dashboard that let users log a mood or check off habits in a
/// single tap without opening their respective full screens.
class DashboardMoodHabitSliders extends StatelessWidget {
  const DashboardMoodHabitSliders({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.notifier,
      builder: (context, locale, _) {
        return Column(
          children: [
            _MoodSliderCard(scheme: scheme),
            const SizedBox(height: 12),
            _HabitsSliderCard(scheme: scheme),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Mood slider
// ---------------------------------------------------------------------------

class _MoodSliderCard extends StatelessWidget {
  final ColorScheme scheme;
  const _MoodSliderCard({required this.scheme});

  Future<void> _save(BuildContext context, int level) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final key = dayKey(today);
    final existing = HiveService.moods.values.cast<MoodEntry?>().firstWhere(
          (e) => dayKey(e!.date) == key,
          orElse: () => null,
        );
    if (existing != null) {
      existing.moodLevel = level;
      existing.createdAt = now;
      await existing.save();
    } else {
      final entry = MoodEntry(
        id: _uuid.v4(),
        date: today,
        moodLevel: level,
        prompt: '',
        body: '',
        createdAt: now,
      );
      await HiveService.moods.put(entry.id, entry);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'আজকের মেজাজ সংরক্ষিত', 'Today\'s mood saved')),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: HiveService.moods.listenable(),
      builder: (context, Box<MoodEntry> box, _) {
        final today = DateTime.now();
        final existing = box.values.cast<MoodEntry?>().firstWhere(
              (e) => dayKey(e!.date) == dayKey(today),
              orElse: () => null,
            );
        final selectedLevel = existing?.moodLevel ?? 0;

        return Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.soft(AppColors.mood),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header — tapping opens the full Mood page so users can
              // write a longer reflection / see history / change the day.
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MoodScreen()),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.mood.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.emoji_emotions_rounded, color: AppColors.mood, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tr(context, 'আজকের মেজাজ কেমন?', 'How is your mood today?'),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: scheme.onSurface),
                        ),
                      ),
                      if (selectedLevel > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: moodColors[selectedLevel - 1].withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            moodLabel(context, selectedLevel),
                            style: TextStyle(color: moodColors[selectedLevel - 1], fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                        ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 18, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 56,
                child: Row(
                  children: List.generate(5, (i) {
                    final lvl = i + 1;
                    final selected = selectedLevel == lvl;
                    final color = moodColors[i];
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: i == 0 || i == 4 ? 0 : 3),
                        child: GestureDetector(
                          onTap: () => _save(context, lvl),
                          child: AnimatedContainer(
                            duration: AppAnimations.fast,
                            decoration: BoxDecoration(
                              color: selected ? color.withValues(alpha: 0.22) : scheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: selected ? color : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              moodEmojis[i],
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Habit slider
// ---------------------------------------------------------------------------

class _HabitsSliderCard extends StatelessWidget {
  final ColorScheme scheme;
  const _HabitsSliderCard({required this.scheme});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return ValueListenableBuilder(
      valueListenable: HiveService.habits.listenable(),
      builder: (context, Box<Habit> box, _) {
        final habits = box.values
            .where((h) => HabitService.isDueToday(h, today: today))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        if (habits.isEmpty) {
          return const SizedBox.shrink();
        }

        final done = habits.where((h) => HabitService.isChecked(h, today)).length;
        final total = habits.length;

        return Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.soft(AppColors.habits),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header — tapping opens the full Habits page so users can
              // see streaks, the weekly grid, and add new habits.
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HabitsScreen()),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.habits.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.habits, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tr(context, 'আজকের অভ্যাস', "Today's Habits"),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: scheme.onSurface),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.habits.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$done / $total',
                          style: const TextStyle(color: AppColors.habits, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 18, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: habits.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final h = habits[i];
                    final done = HabitService.isChecked(h, today);
                    final color = Color(h.colorValue);
                    return _HabitPill(
                      habit: h,
                      done: done,
                      color: color,
                      onTap: () => HabitService.setChecked(h, today, !done),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HabitPill extends StatelessWidget {
  final Habit habit;
  final bool done;
  final Color color;
  final VoidCallback onTap;
  const _HabitPill({required this.habit, required this.done, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: done ? color : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: done ? color : scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, size: 14, color: done ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              habit.title,
              style: TextStyle(
                color: done ? Colors.white : scheme.onSurface,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

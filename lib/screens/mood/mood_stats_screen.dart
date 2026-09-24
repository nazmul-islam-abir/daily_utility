import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/mood_entry.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import 'mood_screen.dart';

/// Mood stats — design #3. Streak, top mood, weekly trend bar chart,
/// mood distribution list, activity heatmap, mindful moment footer.
class MoodStatsScreen extends StatelessWidget {
  const MoodStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.notifier,
      builder: (context, locale, _) {
        return ValueListenableBuilder(
          valueListenable: HiveService.moods.listenable(),
          builder: (context, Box<MoodEntry> box, _) {
            final entries = box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Row(
                  children: [
                    Expanded(child: _statTile(tr(context, 'ধারা', 'Streak'), '${streakDays(entries)}', tr(context, 'দিন', 'Days'), Icons.local_fire_department_outlined, AppColors.mood)),
                    const SizedBox(width: 10),
                    Expanded(child: _statTile(tr(context, 'শীর্ষ মেজাজ', 'Top Mood'), topMoodLabel(context, entries), '', Icons.emoji_emotions_outlined, _topMoodColor(entries))),
                  ],
                ),
                const SizedBox(height: 24),
                _WeeklyTrendCard(entries: entries),
                const SizedBox(height: 24),
                Text(tr(context, 'মেজাজ বিতরণ', 'Mood Distribution'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Align(alignment: Alignment.centerRight, child: Text(_monthLabel(), style: const TextStyle(fontSize: 12, color: AppColors.textMuted, letterSpacing: 0.6, fontWeight: FontWeight.w800))),
                const SizedBox(height: 8),
                _DistributionCard(entries: entries),
                const SizedBox(height: 24),
                Text(tr(context, 'অ্যাক্টিভিটি হিটম্যাপ', 'Activity Heatmap'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                _Heatmap(entries: entries),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE0EAFF), Color(0xFFF2F4F8)]), borderRadius: BorderRadius.circular(AppRadius.xl)),
                  child: Column(
                    children: [
                      Text(tr(context, 'সচেতন মুহূর্ত', 'Mindful Moment'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.text)),
                      const SizedBox(height: 8),
                      Text(
                        tr(context, 'আপনি গত মাসের তুলনায় ২০% বেশি ইতিবাচক বোধ করছেন। প্রতিফলন চালিয়ে যান।', 'You feel 20% more positive than last month. Keep reflecting.'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _monthLabel() {
    const m = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return m[DateTime.now().month - 1];
  }

  Widget _statTile(String label, String value, String suffix, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 16), const SizedBox(width: 6), Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w800))]),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          if (suffix.isNotEmpty) Text(suffix, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  int streakDays(List<MoodEntry> entries) {
    if (entries.isEmpty) return 0;
    int streak = 0;
    var d = DateTime.now();
    final today = DateTime(d.year, d.month, d.day);
    final key = dayKey(today);
    final hasToday = entries.any((e) => dayKey(e.date) == key);
    if (!hasToday) {
      d = d.subtract(const Duration(days: 1));
    }
    while (true) {
      final k = dayKey(d);
      if (entries.any((e) => dayKey(e.date) == k)) {
        streak++;
        d = d.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  String topMoodLabel(BuildContext context, List<MoodEntry> entries) {
    if (entries.isEmpty) return '—';
    final tally = <int, int>{};
    for (final e in entries) {
      tally[e.moodLevel] = (tally[e.moodLevel] ?? 0) + 1;
    }
    final top = tally.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return moodLabel(context, top);
  }

  Color _topMoodColor(List<MoodEntry> entries) {
    if (entries.isEmpty) return AppColors.mood;
    final tally = <int, int>{};
    for (final e in entries) {
      tally[e.moodLevel] = (tally[e.moodLevel] ?? 0) + 1;
    }
    final top = tally.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return moodColors[top - 1];
  }
}

class _WeeklyTrendCard extends StatelessWidget {
  final List<MoodEntry> entries;
  const _WeeklyTrendCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final counts = List.generate(7, (i) {
      final d = weekStart.add(Duration(days: i));
      return entries.where((e) => dayKey(e.date) == dayKey(d)).fold<int>(0, (s, e) => s + e.moodLevel);
    });
    final maxC = counts.fold<int>(0, (a, b) => a > b ? a : b).clamp(1, 1000);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(context, 'সাপ্তাহিক প্রবণতা', 'Weekly Trend'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final c = counts[i];
                final h = (c / maxC) * 100;
                final isToday = i == today.weekday - 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: AppAnimations.medium,
                          height: h,
                          decoration: BoxDecoration(color: isToday ? AppColors.text : AppColors.primary.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
                        ),
                        const SizedBox(height: 6),
                        Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][i], style: TextStyle(fontSize: 11.5, color: isToday ? AppColors.text : AppColors.textMuted, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  final List<MoodEntry> entries;
  const _DistributionCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final total = entries.length;
    final counts = List.generate(5, (i) => entries.where((e) => e.moodLevel == i + 1).length);
    final reversedCounts = counts.reversed.toList();
    final reversedColors = moodColors.reversed.toList();
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Column(
        children: List.generate(5, (i) {
          final pct = total == 0 ? 0 : (reversedCounts[i] / total * 100).round();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: reversedColors[i], shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(child: Text(moodLabel(context, [5,4,3,2,1][i]), style: const TextStyle(fontWeight: FontWeight.w700))),
                Text('$pct%', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textMuted)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  final List<MoodEntry> entries;
  const _Heatmap({required this.entries});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = 28;
    final start = today.subtract(Duration(days: days - 1));
    final tallyByDay = <String, int>{};
    for (final e in entries) {
      final k = dayKey(e.date);
      tallyByDay[k] = (tallyByDay[k] ?? 0) + 1;
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Column(
        children: [
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))))).toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4, childAspectRatio: 1),
            itemCount: days,
            itemBuilder: (context, i) {
              final d = start.add(Duration(days: i));
              final k = dayKey(d);
              final c = tallyByDay[k] ?? 0;
              Color color;
              if (c == 0) {
                color = AppColors.surfaceAlt;
              } else if (c == 1) {
                color = AppColors.primary.withValues(alpha: 0.4);
              } else if (c == 2) {
                color = AppColors.primary.withValues(alpha: 0.7);
              } else {
                color = AppColors.text;
              }
              return Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)));
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(tr(context, 'কম', 'Less'), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              const SizedBox(width: 6),
              ...[0.0, 0.4, 0.7, 1.0].map((a) => Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Container(width: 14, height: 14, decoration: BoxDecoration(color: a == 0 ? AppColors.surfaceAlt : AppColors.primary.withValues(alpha: a), borderRadius: BorderRadius.circular(3))))),
              const SizedBox(width: 6),
              Text(tr(context, 'বেশি', 'More'), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
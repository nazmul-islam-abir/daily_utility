import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/mood_entry.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'mood_screen.dart';

/// Mood entries — chronological list of every saved reflection.
class MoodEntriesScreen extends StatelessWidget {
  const MoodEntriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.notifier,
      builder: (context, locale, _) {
        return ValueListenableBuilder(
          valueListenable: HiveService.moods.listenable(),
          builder: (context, Box<MoodEntry> box, _) {
            final entries = box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
            if (entries.isEmpty) {
              return EmptyState(
                icon: Icons.emoji_emotions_outlined,
                title: tr(context, 'কোনো এন্ট্রি নেই', 'No entries yet'),
                message: tr(context, 'Mood ট্যাবে গিয়ে প্রথম প্রতিফলন লিখুন', 'Write your first reflection from the Mood tab'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: entries.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.history_rounded, size: 16, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(
                          tr(context, '${entries.length} টি এন্ট্রি', '${entries.length} entries'),
                          style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  );
                }
                final e = entries[i - 1];
                final color = moodColors[e.moodLevel - 1];
                return Dismissible(
                  key: ValueKey(e.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(AppRadius.lg)),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  confirmDismiss: (_) async => confirmDelete(context, title: tr(context, 'এন্ট্রি মুছবেন?', 'Delete entry?')),
                  onDismissed: (_) => e.delete(),
                  child: PressableCard(
                    color: scheme.surface,
                    padding: const EdgeInsets.all(14),
                    onTap: () => _showDetail(context, e),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GradientIconTile(icon: _iconForMood(e.moodLevel), color: color, size: 44, gradient: false),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(moodLabel(context, e.moodLevel), style: TextStyle(fontWeight: FontWeight.w900, color: color)),
                                  const Spacer(),
                                  Text(
                                    DateFormat('d MMM y').format(e.date),
                                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                              if (e.body.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    e.body,
                                    style: TextStyle(fontSize: 13, color: scheme.onSurface),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  IconData _iconForMood(int level) {
    switch (level) {
      case 1:
        return Icons.sentiment_very_dissatisfied;
      case 2:
        return Icons.sentiment_dissatisfied;
      case 3:
        return Icons.sentiment_neutral;
      case 4:
        return Icons.sentiment_satisfied;
      case 5:
        return Icons.sentiment_very_satisfied;
      default:
        return Icons.emoji_emotions_outlined;
    }
  }

  void _showDetail(BuildContext context, MoodEntry e) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(moodEmojis[e.moodLevel - 1], style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 8),
                Text(
                  moodLabel(context, e.moodLevel),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: scheme.onSurface),
                ),
                const Spacer(),
                Text(
                  DateFormat('d MMM y').format(e.date),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (e.prompt.isNotEmpty)
              Text(
                e.prompt,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: scheme.onSurfaceVariant),
              ),
            const SizedBox(height: 8),
            Text(
              e.body.isEmpty ? tr(context, 'কোনো লেখা নেই', 'No additional text') : e.body,
              style: TextStyle(fontSize: 15, color: scheme.onSurface, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

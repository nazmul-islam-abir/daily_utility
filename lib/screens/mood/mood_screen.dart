import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/mood_entry.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'mood_entries_screen.dart';
import 'mood_logger_screen.dart';
import 'mood_stats_screen.dart';

/// Mood screen — design #7/#3. Holds its own 4-tab sub-navigation
/// (Entries / Mood / Stats / Settings) matching the reference.
class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  int _tab = 1; // default to the logger (Mood)

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.notifier,
      builder: (context, locale, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            title: Text(tr(context, 'মেজাজ', 'Daily Reflect'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            actions: [
              IconButton(icon: const Icon(Icons.account_circle_outlined), onPressed: () {}),
            ],
          ),
          body: AnimatedSwitcher(
            duration: AppAnimations.medium,
            switchInCurve: AppAnimations.curve,
            switchOutCurve: AppAnimations.curve,
            child: _buildTab(_tab),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.mood.withValues(alpha: 0.18),
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              NavigationDestination(icon: const Icon(Icons.notes_outlined), selectedIcon: Icon(Icons.notes, color: AppColors.mood), label: tr(context, 'এন্ট্রি', 'Entries')),
              NavigationDestination(icon: const Icon(Icons.emoji_emotions_outlined), selectedIcon: Icon(Icons.emoji_emotions, color: AppColors.mood), label: tr(context, 'মেজাজ', 'Mood')),
              NavigationDestination(icon: const Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart, color: AppColors.mood), label: tr(context, 'পরিসংখ্যান', 'Stats')),
              NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: AppColors.mood), label: tr(context, 'সেটিংস', 'Settings')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(int i) {
    switch (i) {
      case 0:
        return const KeyedSubtree(key: ValueKey('entries'), child: MoodEntriesScreen());
      case 1:
        return const KeyedSubtree(key: ValueKey('logger'), child: MoodLoggerScreen());
      case 2:
        return const KeyedSubtree(key: ValueKey('stats'), child: MoodStatsScreen());
      default:
        return KeyedSubtree(key: const ValueKey('settings'), child: _MoodSettings());
    }
  }
}

class _MoodSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.notifications_outlined, color: AppColors.primary),
            title: Text(tr(context, 'দৈনিক রিমাইন্ডার', 'Daily reminder'), style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(tr(context, 'প্রতিদিন রাত ৯টায় লেখার কথা মনে করিয়ে দিন', 'Remind me to write at 9 PM every day')),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.danger),
            title: Text(tr(context, 'সব এন্ট্রি মুছুন', 'Delete all entries'), style: const TextStyle(fontWeight: FontWeight.w700)),
            onTap: () async {
              final ok = await confirmDelete(context, title: tr(context, 'সব এন্ট্রি মুছবেন?', 'Delete every entry?'));
              if (ok) await HiveService.moods.clear();
            },
          ),
        ),
      ],
    );
  }
}

/// 5 emoji faces mapped to mood levels 1..5.
const moodLabels = [
  ['', ''], // dummy index
  ['ভয়ানক', 'Awful'],
  ['খারাপ', 'Bad'],
  ['মোটামুটি', 'Okay'],
  ['ভালো', 'Good'],
  ['দারুণ', 'Amazing'],
];

String moodLabel(BuildContext context, int level) {
  final row = moodLabels[level];
  return tr(context, row[0], row[1]);
}

const moodEmojis = ['😖', '😕', '😐', '🙂', '😄'];

const moodColors = [
  Color(0xFFE1493D), // Awful
  Color(0xFFFB923C), // Bad
  Color(0xFFE0A628), // Okay
  Color(0xFF14B8A6), // Good
  Color(0xFF10B981), // Amazing
];

/// Format a DateTime as yyyy-mm-dd (date key for one entry per day).
String dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

/// All mood entries for one date.
MoodEntry? entryForDate(DateTime date) {
  final key = dayKey(date);
  for (final e in HiveService.moods.values) {
    if (dayKey(e.date) == key) return e;
  }
  return null;
}

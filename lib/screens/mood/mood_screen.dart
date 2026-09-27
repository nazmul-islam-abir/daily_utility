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

/// Mood screen — Daily Reflect. Uses top TabBar navigation embedded in AppBar
/// to avoid double bottom navigation bars.
class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.notifier,
      builder: (context, locale, _) {
        return Scaffold(
          backgroundColor: scheme.surfaceContainerLow,
          appBar: AppBar(
            title: Text(tr(context, 'মেজাজ', 'Daily Reflect')),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: AppColors.mood,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: scheme.onSurfaceVariant,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  padding: const EdgeInsets.all(3),
                  tabs: [
                    Tab(text: tr(context, 'এন্ট্রি', 'Entries')),
                    Tab(text: tr(context, 'মেজাজ', 'Mood')),
                    Tab(text: tr(context, 'পরিসংখ্যান', 'Stats')),
                    Tab(text: tr(context, 'সেটিংস', 'Settings')),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              MoodEntriesScreen(),
              MoodLoggerScreen(),
              MoodStatsScreen(),
              _MoodSettings(),
            ],
          ),
        );
      },
    );
  }
}

class _MoodSettings extends StatelessWidget {
  const _MoodSettings();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          color: scheme.surface,
          child: ListTile(
            leading: const Icon(Icons.notifications_outlined, color: AppColors.primary),
            title: Text(
              tr(context, 'দৈনিক রিমাইন্ডার', 'Daily reminder'),
              style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
            ),
            subtitle: Text(
              tr(context, 'প্রতিদিন রাত ৯টায় লেখার কথা মনে করিয়ে দিন', 'Remind me to write at 9 PM every day'),
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: scheme.surface,
          child: ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.danger),
            title: Text(
              tr(context, 'সব এন্ট্রি মুছুন', 'Delete all entries'),
              style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
            ),
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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/loan.dart';
import '../../models/note.dart';
import '../../models/post.dart';
import '../../models/shopping_item.dart';
import '../../models/todo_item.dart';
import '../../models/habit.dart';
import '../../services/data_refresh_service.dart';
import '../../services/habit_service.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../services/notice_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dashboard_sliders.dart';
import '../baki_khata/baki_khata_screen.dart';
import '../calculator/calculator_hub_screen.dart';
import '../date_tools/date_tools_screen.dart';
import '../finance/add_transaction_screen.dart';
import '../finance/finance_home_screen.dart';
import '../habits/habits_screen.dart';
import '../history/history_screen.dart';
import '../loan/loan_screen.dart';
import '../mood/mood_screen.dart';
import '../more/more_screen.dart';
import '../notes/note_editor_screen.dart';
import '../notes/notes_list_screen.dart';
import '../notes/simple_note_sheet.dart';
import '../notices/notices_screen.dart';
import '../posts/post_editor_screen.dart';
import '../posts/posts_list_screen.dart';
import '../prayer/prayer_screen.dart';
import '../quiz/quiz_categories_screen.dart';
import '../reminders/reminders_screen.dart';
import '../settings/settings_screen.dart';
import '../shopping/shopping_list_screen.dart';
import '../subscription/subscriptions_screen.dart';
import '../todo/todo_editor_screen.dart';
import '../todo/todo_list_screen.dart';
import '../unit_converter/unit_converter_screen.dart';
import '../vault/vault_screen.dart';

/// Main app shell with bottom navigation:
/// Home / Notes / [+] Add / Backup / More
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  DateTime? _lastBackPressed;

  static const _pages = <Widget>[
    _HomeTab(),
    _NotesTab(),
    _MoodTab(),
    _HabitTab(),
    _MoreTab(),
  ];

  void _setIndex(int i) {
    setState(() => _index = i);
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _QuickAddSheet(),
    );
  }

  Future<bool> _onWillPop() async {
    if (_index != 0) {
      setState(() => _index = 0);
      return false;
    }
    final now = DateTime.now();
    if (_lastBackPressed == null || now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.exit_to_app, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(tr(context, 'অ্যাপ থেকে বের হতে আবার ব্যাক চাপুন', 'Press back again to exit')),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: _pages),
        // Hide the global Quick-Add FAB on tabs that already have their own
        // (Mood/Habit screens bring their own FABs).
        floatingActionButton: (_index == 2 || _index == 3)
            ? null
            : FloatingActionButton(
                onPressed: _showAddSheet,
                child: const Icon(Icons.add, size: 28),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) {
            // Index 0 = Home, 1 = Note, 2 = Mood, 3 = Habit, 4 = More.
            _setIndex(i);
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard_rounded),
              label: tr(context, 'হোম', 'Home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.note_alt_outlined),
              selectedIcon: const Icon(Icons.note_alt),
              label: tr(context, 'নোট', 'Note'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.emoji_emotions_outlined),
              selectedIcon: const Icon(Icons.emoji_emotions),
              label: tr(context, 'মেজাজ', 'Mood'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.spa_outlined),
              selectedIcon: const Icon(Icons.spa),
              label: tr(context, 'অভ্যাস', 'Habit'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_rounded),
              selectedIcon: const Icon(Icons.menu_open_rounded),
              label: tr(context, 'আরও', 'More'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HOME TAB — Ultra Unique Creator & Utility Hub Dashboard (No Lazy Loading)
// ============================================================================

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  String _greeting(BuildContext context) {
    final h = DateTime.now().hour;
    final bn = Localizations.localeOf(context).languageCode == 'bn';
    if (bn) {
      if (h < 12) return 'শুভ সকাল';
      if (h < 17) return 'শুভ দুপুর';
      if (h < 20) return 'শুভ সন্ধ্যা';
      return 'শুভ রাত্রি';
    }
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 20) return 'Good evening';
    return 'Good night';
  }

  void _openMore(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MoreScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = SettingsService.instance.userName;
    final todos = Hive.box<TodoItem>('todos');
    final notes = Hive.box<Note>('notes');
    final loans = Hive.box<Loan>('loans');
    final shopping = Hive.box<ShoppingItem>('shopping');

    return AnimatedBuilder(
      animation: Listenable.merge([
        todos.listenable(),
        notes.listenable(),
        loans.listenable(),
        shopping.listenable(),
        HiveService.posts.listenable(),
        HiveService.subscriptions.listenable(),
        DataRefreshService.instance.notifier,
      ]),
      builder: (context, _) {
        final pendingTodos = todos.values.where((t) => !t.isCompleted).length;
        final completedTodos = todos.values.where((t) => t.isCompleted).length;
        final totalTodos = todos.length;
        final totalNotes = notes.length;
        final activeLoans = loans.length;
        final shoppingLeft = shopping.values.where((s) => !s.checked).length;
        final postsList = HiveService.posts.values.toList();

        // Counts for the new Mood + Habit category cards.
        final now = DateTime.now();
        final moodCount = HiveService.moods.length;
        final habitsBox = Hive.box<Habit>('habits');
        final habitsCount = habitsBox.length;
        final habitsDueToday = habitsBox
            .values
            .where((h) => HabitService.isDueToday(h, today: now))
            .length;

        DateFormat('EEEE, d MMM').format(now);

        final categories = <_GivingliCategoryCardData>[
          _GivingliCategoryCardData(
            title: tr(context, 'উৎপাদনশীলতা', 'Productivity'),
            subtitle: tr(context, '$pendingTodos টি কাজ • $totalNotes টি নোট', '$pendingTodos tasks • $totalNotes notes'),
            icon: Icons.auto_awesome_rounded,
            color: const Color(0xFF6366F1),
            gradient: const [Color(0xFF6366F1), Color(0xFF4338CA)],
            screen: const TodoListScreen(),
          ),
          _GivingliCategoryCardData(
            title: tr(context, 'অর্থ ও হিসাব', 'Finance'),
            subtitle: tr(context, 'ব্যালেন্স • বাকি • $activeLoansটি লোন', 'Balance • Baki • $activeLoans loans'),
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFF10B981),
            gradient: const [Color(0xFF10B981), Color(0xFF047857)],
            screen: const FinanceHomeScreen(),
          ),
          // Dedicated Mood card — opens the full Mood page so the user
          // can write today's reflection and browse history.
          _GivingliCategoryCardData(
            title: tr(context, 'মেজাজ', 'Mood'),
            subtitle: tr(context, '$moodCount টি এন্ট্রি • আজকের প্রতিফলন', '$moodCount entries • log today'),
            icon: Icons.emoji_emotions_rounded,
            color: const Color(0xFFF59E0B),
            gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
            screen: const MoodScreen(),
          ),
          // Dedicated Habit card — opens the full Habits page so the user
          // can manage routines and check off today's habits.
          _GivingliCategoryCardData(
            title: tr(context, 'অভ্যাস', 'Habits'),
            subtitle: tr(context, '$habitsDueToday টি আজ • মোট $habitsCount', '$habitsDueToday today • $habitsCount total'),
            icon: Icons.spa_rounded,
            color: const Color(0xFF14B8A6),
            gradient: const [Color(0xFF14B8A6), Color(0xFF0F766E)],
            screen: const HabitsScreen(),
          ),
          _GivingliCategoryCardData(
            title: tr(context, 'সরঞ্জাম', 'Tools'),
            subtitle: tr(context, 'ক্যালকুলেটর • শপিং ($shoppingLeft) • সময়', 'Calculators • Shop ($shoppingLeft) • Prayer'),
            icon: Icons.widgets_rounded,
            color: const Color(0xFF06B6D4),
            gradient: const [Color(0xFF06B6D4), Color(0xFF0E7490)],
            screen: const CalculatorHubScreen(),
          ),
        ];

        final featuredSections = <_Section>[
          _Section(tr(context, 'কাজ', 'Todo'), tr(context, '$pendingTodos টি বাকি', '$pendingTodos pending'), Icons.check_circle_outline, AppColors.todo, const TodoListScreen()),
          _Section(tr(context, 'নোট', 'Notes'), tr(context, '$totalNotes টি নোট', '$totalNotes notes'), Icons.sticky_note_2_outlined, AppColors.notes, const NotesListScreen()),
          _Section(tr(context, 'পোস্ট', 'Posts'), tr(context, '${postsList.length}টি পোস্ট', '${postsList.length} posts'), Icons.style_outlined, AppColors.post, const PostsListScreen()),
          _Section(tr(context, 'আয়-ব্যয়', 'Finance'), tr(context, 'ব্যালেন্স ও খরচ', 'Balance & spending'), Icons.account_balance_wallet_outlined, AppColors.finance, const FinanceHomeScreen()),
          _Section(tr(context, 'বাকি খাতা', 'Baki Khata'), tr(context, 'ধারের হিসাব', 'Lend & borrow'), Icons.people_outline, AppColors.bakiKhata, const BakiKhataScreen()),
          _Section(tr(context, 'সাবস্ক্রিপশন', 'Subscriptions'), tr(context, 'মাসিক খরচ', 'Active plans'), Icons.subscriptions_outlined, AppColors.subscription, const SubscriptionsScreen()),
          // Direct Mood + Habit shortcuts — tapping these opens the full
          // page so the user can record their data with full detail.
          _Section(tr(context, 'মেজাজ', 'Mood'), tr(context, '$moodCount টি এন্ট্রি • প্রতিফলন', '$moodCount entries • reflect'), Icons.emoji_emotions_outlined, AppColors.mood, const MoodScreen()),
          _Section(tr(context, 'অভ্যাস', 'Habits'), tr(context, '$habitsDueToday / $habitsCount আজ', '$habitsDueToday / $habitsCount today'), Icons.spa_outlined, AppColors.habits, const HabitsScreen()),
          _Section(tr(context, 'ক্যালকুলেটর', 'Calculator'), tr(context, '৫টি বিভাগ', '5 categories'), Icons.calculate_outlined, AppColors.calculator, const CalculatorHubScreen()),
          _Section(tr(context, 'নামাজ ও কিবলা', 'Prayer & Qibla'), tr(context, 'সময়সূচি ও কম্পাস', 'Schedule & compass'), Icons.mosque_outlined, AppColors.prayer, const PrayerScreen()),
        ];

        return Scaffold(
          drawer: const AppDrawer(),
          appBar: AppBar(
            backgroundColor: scheme.surfaceContainerLow,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, size: 26),
                tooltip: tr(context, 'মেনু', 'Menu'),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('UTILITYHUB', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: scheme.primary, letterSpacing: 1.2)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        children: [
                          const CircleAvatar(radius: 2.5, backgroundColor: AppColors.success),
                          const SizedBox(width: 4),
                          Text(tr(context, '• লাইভ', '• Live'), style: const TextStyle(color: AppColors.success, fontSize: 9.5, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_greeting(context)}, $name',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            actions: [
              ValueListenableBuilder<List<Notice>>(
                valueListenable: NoticeService.instance.notices,
                builder: (context, list, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: NoticeService.instance.configured,
                    builder: (context, configured, _) {
                      final showBadge = configured && list.isNotEmpty;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            tooltip: tr(context, 'নোটিশ', 'Notices'),
                            icon: const Icon(Icons.notifications_none_rounded),
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const NoticesScreen()),
                              );
                              if (context.mounted) {
                                // Refresh on return so unread state stays fresh.
                                NoticeService.instance.refresh();
                              }
                            },
                          ),
                          if (showBadge)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.danger,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: scheme.surfaceContainerLow, width: 1.5),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  list.length > 99 ? '99+' : '${list.length}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, height: 1.1),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
              IconButton(
                tooltip: tr(context, 'সেটিংস', 'Settings'),
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            physics: const BouncingScrollPhysics(),
            children: [
              // 1. Command Search Bar & Quick Shortcuts Row
              const _SearchBarWidget(),
              const SizedBox(height: 10),
              _buildQuickShortcutsRow(context, scheme),
              const SizedBox(height: 14),

              // 1b. Mood & Habit sliders — one-tap logging from the dashboard.
              const DashboardMoodHabitSliders(),
              const SizedBox(height: 16),

              // 2. Active Stories & Broadcast Carousel ("ACTIVE STORIES & BROADCAST")
              _buildHeaderLabel(context, tr(context, 'সক্রিয় গল্প ও পোস্ট ব্রডকাস্ট', 'ACTIVE STORIES & BROADCAST'), onViewAll: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PostsListScreen()))),
              const SizedBox(height: 8),
              _buildActiveStoriesCarousel(context, scheme, postsList),
              const SizedBox(height: 16),

              // 3. Social Post Studio Module Card ("SOCIAL POST STUDIO")
              _buildSocialPostStudioModule(context, scheme, postsList),
              const SizedBox(height: 16),

              // 4. Tactical Utility Nibbles ("TACTICAL UTILITY NIBBLES")
              _buildHeaderLabel(context, tr(context, 'কুইক টুলস ও সুবিধা', 'TACTICAL UTILITY NIBBLES'), onViewAll: () => _openMore(context)),
              const SizedBox(height: 8),
              _buildTacticalNibblesCarousel(context, scheme),
              const SizedBox(height: 16),

              // 5. Priority Tasks Module Widget ("PRIORITY TASKS")
              _buildPriorityTasksModule(context, scheme, todos, completedTodos, totalTodos),
              const SizedBox(height: 16),

              // 6. Treasury Pulse & Finance Widget ("TREASURY PULSE")
              _buildTreasuryPulseModule(context, scheme),
              const SizedBox(height: 16),

              // 7. Mindful Journal Widget ("MINDFUL JOURNAL")
              _buildMindfulJournalModule(context, scheme, totalNotes),
              const SizedBox(height: 16),

              // 8. Givingli Style Categories Carousel
              _SectionHeader(
                title: tr(context, 'ক্যাটাগরি', 'Categories'),
                onViewAll: () => _openMore(context),
              ),
              SizedBox(
                height: 185,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final c = categories[i];
                    return _GivingliCategoryCard(
                      title: c.title,
                      subtitle: c.subtitle,
                      icon: c.icon,
                      color: c.color,
                      gradient: c.gradient,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => c.screen)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 9. Featured Utilities Grid
              _SectionHeader(
                title: tr(context, 'ফিচার সমুহ', 'Featured Utilities'),
                onViewAll: () => _openMore(context),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 12.0;
                  final w = (constraints.maxWidth - spacing) / 2;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (int i = 0; i < featuredSections.length; i++)
                        SizedBox(
                          width: w,
                          height: 128,
                          child: StaggeredFadeIn(
                            index: i,
                            child: SectionCard(
                              title: featuredSections[i].title,
                              subtitle: featuredSections[i].subtitle,
                              icon: featuredSections[i].icon,
                              color: featuredSections[i].color,
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => featuredSections[i].screen)),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderLabel(BuildContext context, String title, {required VoidCallback onViewAll}) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        InkWell(
          onTap: onViewAll,
          child: Text(
            tr(context, 'সব দেখুন ->', 'Manage ->'),
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: scheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickShortcutsRow(BuildContext context, ColorScheme scheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _shortcutPill(context, tr(context, '⚡ কম্পাস', '⚡ Compass'), AppColors.prayer, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrayerScreen()))),
          const SizedBox(width: 8),
          _shortcutPill(context, tr(context, '🧮 ক্যালকুলেটর', '🧮 Calc'), AppColors.calculator, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CalculatorHubScreen()))),
          const SizedBox(width: 8),
          _shortcutPill(context, tr(context, '🔒 ভল্ট', '🔒 Vault'), AppColors.vault, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VaultScreen()))),
          const SizedBox(width: 8),
          _shortcutPill(context, tr(context, '📝 নোট', '📝 Note'), AppColors.notes, () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: scheme.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (_) => const SimpleNoteSheet())),
        ],
      ),
    );
  }

  Widget _shortcutPill(BuildContext context, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _buildActiveStoriesCarousel(BuildContext context, ColorScheme scheme, List<Post> posts) {
    if (posts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.style_outlined, color: AppColors.post, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr(context, 'সোশ্যাল ব্রডকাস্ট ডেক', 'Social Broadcast Desk'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    Text(tr(context, 'নতুন গল্প বা পোস্ট ব্রডকাস্ট শুরু করুন', 'Start your creative broadcast stream'), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PostEditorScreen())),
                child: Text(tr(context, 'তৈরি করুন', 'Create')),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: posts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final p = posts[i];
          final hasImage = p.imagePaths.isNotEmpty;
          return InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostEditorScreen(initial: p))),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: scheme.shadow.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.post.withValues(alpha: 0.12),
                      image: hasImage && File(p.imagePaths.first).existsSync() ? DecorationImage(image: FileImage(File(p.imagePaths.first)), fit: BoxFit.cover) : null,
                    ),
                    child: !hasImage ? const Center(child: Icon(Icons.style_outlined, color: AppColors.post, size: 24)) : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.post.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text(tr(context, '⏰ শিডিউল করা হয়েছে', '⏰ Scheduled'), style: const TextStyle(color: AppColors.post, fontSize: 10, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(height: 6),
                        Text(p.title.isEmpty ? p.body : p.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
                        const SizedBox(height: 4),
                        Text(tr(context, 'পোস্ট পরিচালনা করুন ->', 'Manage Post ->'), style: TextStyle(fontSize: 11, color: scheme.primary, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSocialPostStudioModule(BuildContext context, ColorScheme scheme, List<Post> posts) {
    final topPost = posts.firstOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hub_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(tr(context, 'সোশ্যাল পোস্ট স্টুডিও', 'Social Post Studio'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(tr(context, 'অটো-পোস্ট চালু', 'Auto-post ON'), style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: scheme.surfaceContainerHigh.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(radius: 12, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white, size: 14)),
                      const SizedBox(width: 8),
                      Text(tr(context, 'রিভিয়েরা স্টুডিও', 'riviera.studio'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
                      const Spacer(),
                      Icon(Icons.more_horiz, color: scheme.onSurfaceVariant, size: 18),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    topPost?.body.isNotEmpty == true ? topPost!.body : tr(context, 'এমন টুলস ডিজাইন করা যা শান্ত মনোযোগ জাগায়। আমাদের পূর্ণ ট্যাকটাইল ওয়ার্কস্পেস জার্নাল ডেকে লাইভ।', 'Designing tools that spark quiet focus. Our full tactile workspace is live on the journal deck.'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(tr(context, '#কর্মক্ষেত্র #ন্যূনতমসেটআপ #ইউটিলিটিহাব', '#workspace #minimalsetup #utilityhub'), style: TextStyle(fontSize: 11, color: scheme.primary, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PostEditorScreen())),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(tr(context, 'স্টুডিও খুলুন', 'Open Studio')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PostsListScreen())),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: Text(tr(context, 'সব পোস্ট', 'All Posts')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTacticalNibblesCarousel(BuildContext context, ColorScheme scheme) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _nibbleCard(
            context,
            title: tr(context, 'শেষ হিসাব', 'Last Calculation'),
            value: tr(context, '৩,৪৫০ + ১৫% ভ্যাট = ৩,৯৬৭.৫০', '3,450 + 15% VAT = 3,967.50'),
            buttonText: tr(context, 'ক্যালকুলেটর', 'Open Calc'),
            icon: Icons.history_rounded,
            color: AppColors.calculator,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CalculatorHubScreen())),
          ),
          const SizedBox(width: 12),
          _nibbleCard(
            context,
            title: tr(context, 'একক রূপান্তর', 'Unit Conversion'),
            value: tr(context, 'ইউএসডি/ইইউআর \$১.০০ = €০.৯২', 'USD/EUR \$1.00 = €0.92'),
            buttonText: tr(context, 'রূপান্তর', 'Convert Units'),
            icon: Icons.straighten,
            color: AppColors.converter,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UnitConverterScreen())),
          ),
          const SizedBox(width: 12),
          _nibbleCard(
            context,
            title: tr(context, 'নামাজ ও কিবলা', 'Prayer Schedule'),
            value: tr(context, 'কিবলা দিক ও সময়সূচি', 'Qibla live direction'),
            buttonText: tr(context, 'কম্পাস', 'Qibla Compass'),
            icon: Icons.mosque_outlined,
            color: AppColors.prayer,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrayerScreen())),
          ),
        ],
      ),
    );
  }

  Widget _nibbleCard(BuildContext context, {required String title, required String value, required String buttonText, required IconData icon, required Color color, required VoidCallback onTap}) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: scheme.shadow.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: scheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
            const Spacer(),
            Text(buttonText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityTasksModule(BuildContext context, ColorScheme scheme, Box<TodoItem> todos, int completed, int total) {
    final pendingList = todos.values.where((t) => !t.isCompleted).take(2).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: AppColors.todo, size: 20),
                const SizedBox(width: 8),
                Text(tr(context, 'প্রধান কাজ সমূহ', 'PRIORITY TASKS'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const Spacer(),
                Text(tr(context, '$completed / $total সম্পন্ন', '$completed of $total Done'), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            if (pendingList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(tr(context, 'সব কাজ সম্পন্ন হয়েছে! 🎉', 'All tasks completed! 🎉'), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w700)),
              )
            else
              for (final t in pendingList)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Checkbox(
                        value: t.isCompleted,
                        activeColor: AppColors.todo,
                        onChanged: (v) {
                          t.isCompleted = v ?? false;
                          t.save();
                        },
                      ),
                      Expanded(
                        child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TodoEditorScreen())),
                icon: const Icon(Icons.add, size: 18),
                label: Text(tr(context, '+ নতুন কাজ', '+ New Task')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreasuryPulseModule(BuildContext context, ColorScheme scheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, color: AppColors.finance, size: 20),
                const SizedBox(width: 8),
                Text(tr(context, 'আর্থিক ব্যালেন্স', 'TREASURY PULSE'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.finance.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(tr(context, 'নিট তারল্য', 'Net Liquidity'), style: const TextStyle(color: AppColors.finance, fontSize: 11, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddTransactionScreen())),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(tr(context, 'লেনদেন যোগ', 'Add Transaction')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.finance, foregroundColor: Colors.white),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FinanceHomeScreen())),
                    icon: const Icon(Icons.account_balance, size: 16),
                    label: Text(tr(context, 'অর্থ বিবরণী', 'Open Finance')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMindfulJournalModule(BuildContext context, ColorScheme scheme, int notesCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_outlined, color: AppColors.notes, size: 20),
                const SizedBox(width: 8),
                Text(tr(context, 'দৈনিক ভাবনা ও জার্নাল', 'MINDFUL JOURNAL'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const Spacer(),
                Text(tr(context, '$notesCount টি নোট', '$notesCount Notes'), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 8),
            Text(tr(context, '"আজ আপনি কোন সৃজনশীল সীমানা অন্বেষণ করলেন?"', '"What creative boundary did you explore today?"'), style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.notes, foregroundColor: Colors.white),
                onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: scheme.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (_) => const SimpleNoteSheet()),
                icon: const Icon(Icons.edit_note, size: 20),
                label: Text(tr(context, 'নোট লিখুন 🖋️', 'Write Note 🖋️')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Givingli Search Bar Widget
class _SearchBarWidget extends StatelessWidget {
  const _SearchBarWidget();

  void _openSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _GlobalAppSearchDelegate(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _openSearch(context),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: scheme.onSurfaceVariant, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr(context, 'কাজ, পাসওয়ার্ড, নোট বা ক্যালকুলেটর খুঁজুন...', 'Jump to utility, password, note, or calc...'),
                style: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 13.5, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Givingli Section Header with "View All"
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;

  const _SectionHeader({
    required this.title,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          InkWell(
            onTap: onViewAll,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                tr(context, 'সব দেখুন', 'View All'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GivingliCategoryCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final Widget screen;
  const _GivingliCategoryCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.screen,
  });
}

class _GivingliCategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _GivingliCategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 145,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Title Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            // Large Center Icon Container
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
            ),
            const Spacer(),
            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlobalAppSearchDelegate extends SearchDelegate<String?> {
  @override
  String get searchFieldLabel => 'Search tools, notes, calculators...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final q = query.trim().toLowerCase();
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final allFeatures = <_FeatureItem>[
      _FeatureItem('কাজ ও টাস্ক', 'Todo & Tasks', 'দৈনিক চেকলিস্ট ও কাজ পরিচালনা', 'Manage daily checklists and tasks', Icons.check_circle_outline, AppColors.todo, const TodoListScreen()),
      _FeatureItem('নোট ও খাতা', 'Notes & Khata', 'ধারণা ও নোট লিখুন', 'Write ideas and notes', Icons.sticky_note_2_outlined, AppColors.notes, const NotesListScreen()),
      _FeatureItem('পোস্ট ও ব্রডকাস্ট', 'Posts & Broadcast', 'সৃজনশীল ব্লগ পোস্ট ও সোশ্যাল ফিড', 'Creative blog posts & social feeds', Icons.style_outlined, AppColors.post, const PostsListScreen()),
      _FeatureItem('আয়-ব্যয় ট্র্যাকার', 'Finance Tracker', 'আয় ও ব্যয়ের হিসাব রাখুন', 'Track income and spending', Icons.account_balance_wallet_outlined, AppColors.finance, const FinanceHomeScreen()),
      _FeatureItem('বাকি খাতা', 'Baki Khata', 'ধার-দেনার হিসাব', 'Track lend and borrow debts', Icons.people_outline, AppColors.bakiKhata, const BakiKhataScreen()),
      _FeatureItem('লোন ম্যানেজার', 'Loan Manager', 'চলমান লোন ও কিস্তি', 'Active loans and installments', Icons.credit_card_outlined, AppColors.loan, const LoanScreen()),
      _FeatureItem('ক্যালকুলেটর', 'Calculators', 'সাধারণ ও আর্থিক ক্যালকুলেটর ৫টি বিভাগ', '5 categories of general & finance calculators', Icons.calculate_outlined, AppColors.calculator, const CalculatorHubScreen()),
      _FeatureItem('একক রূপান্তর', 'Unit Converter', 'দৈর্ঘ্য, ওজন, তাপমাত্রা, আয়তন', 'Length, weight, temperature, volume', Icons.straighten, AppColors.converter, const UnitConverterScreen()),
      _FeatureItem('শপিং তালিকা', 'Shopping List', 'মুদি ও কেনাকাটার তালিকা', 'Groceries and buy lists', Icons.shopping_cart_outlined, AppColors.shopping, const ShoppingListScreen()),
      _FeatureItem('অভ্যাস ট্র্যাকার', 'Habit Tracker', 'দৈনিক রুটিন ও স্ট্রিক', 'Daily routines and streaks', Icons.spa_outlined, AppColors.habits, const HabitsScreen()),
      _FeatureItem('মেজাজ ট্র্যাকার', 'Mood Reflector', 'দৈনিক মেজাজ এন্ট্রি ও প্যাটার্ন', 'Daily mood entries and patterns', Icons.emoji_emotions_outlined, AppColors.mood, const MoodScreen()),
      _FeatureItem('পাসওয়ার্ড ভল্ট', 'Password Vault', 'নিরাপদ লোকাল ক্রেডেনশিয়াল', 'Secure local credentials', Icons.lock_outline, AppColors.vault, const VaultScreen()),
      _FeatureItem('দৈনিক কুইজ', 'Daily Quiz', 'প্রতিদিন জ্ঞান যাচাই', 'Test your knowledge daily', Icons.psychology_outlined, AppColors.quiz, const QuizCategoriesScreen()),
      _FeatureItem('তারিখ টুলস', 'Date Tools', 'বয়স ক্যালকুলেটর ও কাউন্টডাউন', 'Age calculator and day countdowns', Icons.event_outlined, AppColors.dateTools, const DateToolsScreen()),
      _FeatureItem('রিমাইন্ডার', 'Reminders', 'সব নির্ধারিত রিমাইন্ডার', 'All scheduled reminders', Icons.alarm_outlined, AppColors.reminders, const RemindersScreen()),
      _FeatureItem('নামাজ ও কিবলা', 'Prayer Times & Qibla', 'নামাজের সময় ও লাইভ কম্পাস', 'Prayer times and live compass', Icons.mosque_outlined, AppColors.prayer, const PrayerScreen()),
      _FeatureItem('ইতিহাস', 'History', 'ক্যালকুলেশন ও লেনদেনের লগ', 'Calculations and transactions log', Icons.history_rounded, AppColors.primary, const HistoryScreen()),
    ];

    final filtered = q.isEmpty
        ? allFeatures
        : allFeatures.where((f) {
            return f.titleBn.toLowerCase().contains(q) ||
                f.titleEn.toLowerCase().contains(q) ||
                f.subtitleBn.toLowerCase().contains(q) ||
                f.subtitleEn.toLowerCase().contains(q);
          }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(tr(context, 'কিছু পাওয়া যায়নি', 'No matching feature found')),
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final f = filtered[i];
        final title = isBn ? f.titleBn : f.titleEn;
        final subtitle = isBn ? f.subtitleBn : f.subtitleEn;
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: f.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(f.icon, color: f.color),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            close(context, null);
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => f.screen));
          },
        );
      },
    );
  }
}

class _Section {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;
  const _Section(this.title, this.subtitle, this.icon, this.color, this.screen);
}

class _FeatureItem {
  final String titleBn;
  final String titleEn;
  final String subtitleBn;
  final String subtitleEn;
  final IconData icon;
  final Color color;
  final Widget screen;
  _FeatureItem(this.titleBn, this.titleEn, this.subtitleBn, this.subtitleEn, this.icon, this.color, this.screen);
}

// ============================================================================
// NOTES TAB — Google Keep-style
// ============================================================================

class _NotesTab extends StatelessWidget {
  const _NotesTab();

  @override
  Widget build(BuildContext context) {
    final notes = Hive.box<Note>('notes');
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: scheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: scheme.surfaceContainerLow,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: tr(context, 'মেনু', 'Menu'),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(tr(context, 'নোট', 'Notes'), style: Theme.of(context).textTheme.headlineSmall),
        actions: [
          IconButton(
            tooltip: tr(context, 'অনুসন্ধান', 'Search'),
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotesListScreen())),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: Listenable.merge([notes.listenable(), DataRefreshService.instance.notifier]),
          builder: (context, _) {
            return ValueListenableBuilder(
              valueListenable: notes.listenable(),
              builder: (context, Box<Note> box, _) {
                final all = box.values.toList()
                  ..sort((a, b) {
                    if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
                    return b.updatedAt.compareTo(a.updatedAt);
                  });
                if (all.isEmpty) {
                  return EmptyState(
                    icon: Icons.lightbulb_outline,
                    title: tr(context, 'আপনার নোটগুলো এখানে দেখা যাবে', 'Notes you add appear here'),
                    message: tr(context, '+ বাটনে চেপে প্রথম নোট লিখুন', 'Tap + to capture your first note'),
                  );
                }
                return _MasonryNotesGrid(notes: all);
              },
            );
          },
        ),
      ),
      // The Note tab opens the FULL note editor directly so users can
      // start writing with one tap. The Quick Note (SimpleNoteSheet) is
      // still available from the center + add sheet.
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.notes,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NoteEditorScreen())),
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }
}

/// Two-column wrap that lets cards of different heights sit flush, the
/// way Google Keep's note grid does.
class _MasonryNotesGrid extends StatelessWidget {
  final List<Note> notes;
  const _MasonryNotesGrid({required this.notes});

  @override
  Widget build(BuildContext context) {
    final left = <Note>[];
    final right = <Note>[];
    for (int i = 0; i < notes.length; i++) {
      if (i.isEven) {
        left.add(notes[i]);
      } else {
        right.add(notes[i]);
      }
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 110),
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _Column(notes: left)),
          const SizedBox(width: 8),
          Expanded(child: _Column(notes: right)),
        ],
      ),
    );
  }
}

class _Column extends StatelessWidget {
  final List<Note> notes;
  const _Column({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final n in notes) _KeepNoteCard(note: n, paddingBottom: 8),
      ],
    );
  }
}

class _KeepNoteCard extends StatelessWidget {
  final Note note;
  final double paddingBottom;
  const _KeepNoteCard({required this.note, this.paddingBottom = 8});

  String _preview(BuildContext context, Note n) {
    if (n.type == 'checklist') {
      final done = n.checklistItems.where((c) => c.checked).length;
      if (n.checklistItems.isEmpty) return LocaleService.isBangla ? 'খালি চেকলিস্ট' : 'Empty checklist';
      final lines = n.checklistItems.take(4).map((c) => '${c.checked ? '☑' : '☐'} ${c.text}').join('\n');
      return '$done/${n.checklistItems.length}\n$lines';
    }
    return n.body.isEmpty ? (LocaleService.isBangla ? 'কোনো লেখা নেই' : 'No additional text') : n.body;
  }

  @override
  Widget build(BuildContext context) {
    final cardColorVal = note.colorValue == 0 ? 0xFFF59E0B : note.colorValue;
    final color = Color(cardColorVal);
    final scheme = Theme.of(context).colorScheme;
    final hasTitle = note.title.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: paddingBottom),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NoteEditorScreen(existing: note))),
          onLongPress: () => _showOptions(context),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasTitle) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          note.title,
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: color.withValues(alpha: 0.95), height: 1.3),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (note.isPinned) Padding(padding: const EdgeInsets.only(left: 4, top: 2), child: Icon(Icons.push_pin, size: 14, color: color)),
                    ],
                  ),
                  const SizedBox(height: 6),
                ] else if (note.isPinned) ...[
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.push_pin, size: 14, color: color),
                    ),
                  ),
                ],
                Text(
                  _preview(context, note),
                  style: TextStyle(
                    fontSize: hasTitle ? 12.5 : 14,
                    fontWeight: hasTitle ? FontWeight.normal : FontWeight.w700,
                    color: scheme.onSurface,
                    height: 1.4,
                  ),
                  maxLines: 12,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (note.type == 'checklist')
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(Icons.check_box_outlined, size: 12, color: color),
                      ),
                    Text(DateFormat('d MMM').format(note.updatedAt), style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.75), fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(note.isPinned ? tr(context, 'পিন মুক্ত করুন', 'Unpin') : tr(context, 'পিন করুন', 'Pin')),
              onTap: () {
                note.isPinned = !note.isPinned;
                note.updatedAt = DateTime.now();
                note.save();
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(tr(context, 'সম্পাদনা', 'Edit')),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => NoteEditorScreen(existing: note)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(tr(context, 'মুছুন', 'Delete'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () async {
                final ok = await confirmDelete(context, title: tr(context, 'নোটটি মুছবেন?', 'Delete this note?'));
                if (ok) note.delete();
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// MOOD TAB — embeds the dedicated Mood screen directly into the navbar so
// users see the full page instantly (no "Opening…" placeholder, no stack
// juggling). MoodScreen already brings its own AppBar + tabs.
// ============================================================================

class _MoodTab extends StatelessWidget {
  const _MoodTab();

  @override
  Widget build(BuildContext context) {
    return const MoodScreen();
  }
}

// ============================================================================
// HABIT TAB — embeds the dedicated Habits screen directly into the navbar.
// ============================================================================

class _HabitTab extends StatelessWidget {
  const _HabitTab();

  @override
  Widget build(BuildContext context) {
    return const HabitsScreen();
  }
}

// ============================================================================
// MORE TAB
// ============================================================================

class _MoreTab extends StatelessWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: scheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: scheme.surfaceContainerLow,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: tr(context, 'মেনু', 'Menu'),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(tr(context, 'আরও', 'More'), style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: const MoreScreen(isEmbedded: true),
    );
  }
}

// ============================================================================
// QUICK-ADD SHEET
// ============================================================================

class _QuickAddSheet extends StatelessWidget {
  const _QuickAddSheet();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: scheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
          ),
          Text(tr(context, 'দ্রুত যোগ করুন', 'Quick add'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _AddTile(icon: Icons.check_circle_outline, label: tr(context, 'কাজ', 'Task'), color: AppColors.todo, onTap: () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TodoEditorScreen())); }),
              _AddTile(icon: Icons.sticky_note_2_outlined, label: tr(context, 'সহজ নোট', 'Quick note'), color: AppColors.notes, onTap: () { Navigator.pop(context); showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: scheme.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (_) => const SimpleNoteSheet()); }),
              _AddTile(icon: Icons.note_alt_outlined, label: tr(context, 'নোট (সম্পূর্ণ)', 'Full note'), color: AppColors.notes, onTap: () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NoteEditorScreen())); }),
              _AddTile(icon: Icons.account_balance_wallet_outlined, label: tr(context, 'লেনদেন', 'Transaction'), color: AppColors.finance, onTap: () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddTransactionScreen())); }),
              _AddTile(icon: Icons.people_outline, label: tr(context, 'বাকি', 'Baki'), color: AppColors.bakiKhata, onTap: () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BakiKhataScreen())); }),
              _AddTile(icon: Icons.shopping_cart_outlined, label: tr(context, 'শপিং', 'Shopping'), color: AppColors.shopping, onTap: () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShoppingListScreen())); }),
              _AddTile(icon: Icons.spa_outlined, label: tr(context, 'অভ্যাস', 'Habit'), color: AppColors.habits, onTap: () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HabitsScreen())); }),
              _AddTile(icon: Icons.lock_outline, label: tr(context, 'ভল্ট', 'Vault'), color: AppColors.vault, onTap: () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VaultScreen())); }),
              _AddTile(icon: Icons.history_rounded, label: tr(context, 'হিস্টোরি', 'History'), color: AppColors.primary, onTap: () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen())); }),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AddTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

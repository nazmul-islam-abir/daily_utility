import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/loan.dart';
import '../../models/note.dart';
import '../../models/post.dart';
import '../../models/shopping_item.dart';
import '../../models/todo_item.dart';
import '../../services/data_refresh_service.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../baki_khata/baki_khata_screen.dart';
import '../calculator/calculator_hub_screen.dart';
import '../date_tools/date_tools_screen.dart';
import '../finance/finance_home_screen.dart';
import '../habits/habits_screen.dart';
import '../history/history_screen.dart';
import '../loan/loan_screen.dart';
import '../mood/mood_screen.dart';
import '../posts/posts_list_screen.dart';
import '../prayer/prayer_screen.dart';
import '../quiz/quiz_categories_screen.dart';
import '../reminders/reminders_screen.dart';
import '../settings/settings_screen.dart';
import '../shopping/shopping_list_screen.dart';
import '../subscription/subscriptions_screen.dart';
import '../todo/todo_list_screen.dart';
import '../notes/notes_list_screen.dart';
import '../backup/backup_screen.dart';
import '../unit_converter/unit_converter_screen.dart';
import '../vault/vault_screen.dart';

/// The "More" / "All Categories" screen — lists all section cards cleanly.
class MoreScreen extends StatelessWidget {
  final bool isEmbedded;
  const MoreScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (isEmbedded) {
      return body;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'সব ক্যাটাগরি', 'All Categories')),
      ),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final todos = Hive.box<TodoItem>('todos');
    final notes = Hive.box<Note>('notes');
    final loans = Hive.box<Loan>('loans');
    final shopping = Hive.box<ShoppingItem>('shopping');
    final posts = Hive.box<Post>('posts');
    final lastBackup = SettingsService.instance.lastBackupAt;

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.notifier,
      builder: (context, locale, _) {
        final pendingTodos = todos.values.where((t) => !t.isCompleted).length;
        final pendingShopping = shopping.values.where((s) => !s.checked).length;

        final items = <_Item>[
          _Item(Icons.check_circle_outline, AppColors.todo, tr(context, 'টুডু', 'Todo'), tr(context, '$pendingTodos কাজ বাকি', '$pendingTodos pending'), const TodoListScreen()),
          _Item(Icons.sticky_note_2_outlined, AppColors.notes, tr(context, 'নোট', 'Notes'), tr(context, '${notes.length}টি নোট', '${notes.length} notes'), const NotesListScreen()),
          _Item(Icons.account_balance_wallet_outlined, AppColors.finance, tr(context, 'আয়-ব্যয়', 'Finance'), tr(context, 'আয়-ব্যয়ের হিসাব', 'Income & expense tracker'), const FinanceHomeScreen()),
          _Item(Icons.people_outline, AppColors.bakiKhata, tr(context, 'বাকি খাতা', 'Baki Khata'), tr(context, 'ধারের হিসাব', 'Track who owes what'), const BakiKhataScreen()),
          _Item(Icons.credit_card_outlined, AppColors.loan, tr(context, 'ঋণ', 'Loan'), tr(context, '${loans.length} চলমান', '${loans.length} active'), const LoanScreen()),
          _Item(Icons.calculate_outlined, AppColors.calculator, tr(context, 'ক্যালকুলেটর', 'Calculator'), tr(context, 'সাধারণ, আর্থিক ও স্বাস্থ্য', 'General, finance & health'), const CalculatorHubScreen()),
          _Item(Icons.compare_arrows_rounded, AppColors.converter, tr(context, 'একক রূপান্তর', 'Unit Converter'), tr(context, 'দৈর্ঘ্য, ওজন, তাপ, আয়তন', 'Length, weight, temp, volume'), const UnitConverterScreen()),
          _Item(Icons.shopping_cart_outlined, AppColors.shopping, tr(context, 'শপিং', 'Shopping'), tr(context, '$pendingShopping বাকি', '$pendingShopping pending'), const ShoppingListScreen()),
          _Item(Icons.autorenew_rounded, AppColors.subscription, tr(context, 'সাবস্ক্রিপশন', 'Subscriptions'), tr(context, '${HiveService.subscriptions.values.where((s) => s.isActive).length}টি সক্রিয়', '${HiveService.subscriptions.values.where((s) => s.isActive).length} active'), const SubscriptionsScreen()),
          _Item(Icons.spa_outlined, AppColors.habits, tr(context, 'অভ্যাস', 'Habits'), tr(context, 'দৈনিক অভ্যাস ও ধারা', 'Daily habits & streaks'), const HabitsScreen()),
          _Item(Icons.emoji_emotions_outlined, AppColors.mood, tr(context, 'মেজাজ', 'Mood'), tr(context, 'প্রতিফলন ও পরিসংখ্যান', 'Reflect & track patterns'), const MoodScreen()),
          _Item(Icons.lock_outline, AppColors.vault, tr(context, 'ভল্ট', 'Vault'), tr(context, 'পাসওয়ার্ড সংরক্ষণ', 'Local credential keeper'), const VaultScreen()),
          _Item(Icons.dynamic_feed_rounded, AppColors.post, tr(context, 'পোস্ট', 'Posts'), tr(context, '${posts.length}টি পোস্ট', '${posts.length} posts'), const PostsListScreen()),
          _Item(Icons.psychology_outlined, AppColors.quiz, tr(context, 'দৈনিক কুইজ', 'Daily Quiz'), tr(context, 'জ্ঞান যাচাই', 'Test your knowledge'), const QuizCategoriesScreen()),
          _Item(Icons.event_outlined, AppColors.dateTools, tr(context, 'তারিখ টুলস', 'Date Tools'), tr(context, 'বয়স, দিন গণনা', 'Age, day counters'), const DateToolsScreen()),
          _Item(Icons.alarm_outlined, AppColors.reminders, tr(context, 'রিমাইন্ডার', 'Reminders'), tr(context, 'সব রিমাইন্ডার', 'All reminders'), const RemindersScreen()),
          _Item(Icons.mosque_outlined, AppColors.prayer, tr(context, 'নামাজ ও কিবলা', 'Prayer & Qibla'), tr(context, 'নামাজের সময় ও কিবলা কম্পাস', 'Prayer times & Qibla compass'), const PrayerScreen()),
        ];

        return AnimatedBuilder(
          animation: Listenable.merge([
            todos.listenable(),
            notes.listenable(),
            loans.listenable(),
            shopping.listenable(),
            HiveService.subscriptions.listenable(),
            posts.listenable(),
            DataRefreshService.instance.notifier,
          ]),
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              children: [
                // Backup Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.save_outlined, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tr(context, 'ব্যাকআপ ও রিস্টোর', 'Backup & restore'),
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lastBackup != null
                                  ? tr(context, 'শেষ ব্যাকআপ: ${DateFormat('d MMM, hh:mm a').format(lastBackup)}', 'Last backup: ${DateFormat('d MMM, hh:mm a').format(lastBackup)}')
                                  : tr(context, 'এখনো কোনো ব্যাকআপ নেই', 'No backup yet'),
                              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BackupScreen())),
                        child: Text(
                          tr(context, 'খুলুন', 'Open'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // History Item
                _listTile(
                  context,
                  Icons.history_rounded,
                  AppColors.primary,
                  tr(context, 'হিস্টোরি', 'History'),
                  tr(context, 'সব হিসাব ও লেনদেনের ইতিহাস', 'Every calculation and transaction'),
                  const HistoryScreen(),
                ),
                const SizedBox(height: 14),

                // Section Label
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                  child: Text(
                    tr(context, 'সব সেকশন', 'All sections').toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // All Items List
                for (final it in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _listTile(context, it.icon, it.color, it.title, it.subtitle, it.screen),
                  ),

                const SizedBox(height: 6),
                _listTile(
                  context,
                  Icons.settings_outlined,
                  scheme.onSurfaceVariant,
                  tr(context, 'সেটিংস', 'Settings'),
                  tr(context, 'থিম, ভাষা, ডেটা', 'Theme, language, data'),
                  const SettingsScreen(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _listTile(BuildContext context, IconData icon, Color color, String title, String subtitle, Widget screen) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: scheme.outline, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget screen;
  _Item(this.icon, this.color, this.title, this.subtitle, this.screen);
}

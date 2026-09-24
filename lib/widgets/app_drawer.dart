import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/loan.dart';
import '../models/note.dart';
import '../models/post.dart';
import '../models/shopping_item.dart';
import '../models/subscription.dart';
import '../models/todo_item.dart';
import '../screens/baki_khata/baki_khata_screen.dart';
import '../screens/calculator/calculator_hub_screen.dart';
import '../screens/date_tools/date_tools_screen.dart';
import '../screens/finance/finance_home_screen.dart';
import '../screens/habits/habits_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/loan/loan_screen.dart';
import '../screens/mood/mood_screen.dart';
import '../screens/notes/notes_list_screen.dart';
import '../screens/posts/posts_list_screen.dart';
import '../screens/prayer/prayer_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/quiz/quiz_screen.dart';
import '../screens/reminders/reminders_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/shopping/shopping_list_screen.dart';
import '../screens/subscription/subscriptions_screen.dart';
import '../screens/todo/todo_list_screen.dart';
import '../screens/unit_converter/unit_converter_screen.dart';
import '../screens/vault/vault_screen.dart';
import '../services/hive_service.dart';
import '../services/locale_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

/// Hamburger drawer used by every section screen. Lists every section,
/// gives one-tap access to history, settings, and the signed-in account
/// info / backup status at the bottom.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.notifier,
      builder: (context, locale, _) {
        return ValueListenableBuilder<int>(
          valueListenable: SettingsService.instance.revision,
          builder: (context, _, __) {
        final email = SettingsService.instance.signedInEmail;
        final name = SettingsService.instance.userName;
        final lastBackup = SettingsService.instance.lastBackupAt;
        return Drawer(
          backgroundColor: scheme.surface,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context: context, name: name, email: email, lastBackup: lastBackup),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _DrawerItem(
                        icon: Icons.home_rounded,
                        color: AppColors.primary,
                        title: tr(context, 'হোম', 'Home'),
                        onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                      ),
                      _DrawerSectionLabel(tr(context, 'কাজ ও নোট', 'Tasks & notes')),
                      _DrawerItem(
                        icon: Icons.check_circle_outline,
                        color: AppColors.todo,
                        title: tr(context, 'টুডু', 'Todo'),
                        badge: _todoBadge(),
                        onTap: () => _push(context, const TodoListScreen()),
                      ),
                      _DrawerItem(
                        icon: Icons.sticky_note_2_outlined,
                        color: AppColors.notes,
                        title: tr(context, 'নোট', 'Notes'),
                        badge: _notesBadge(),
                        onTap: () => _push(context, const NotesListScreen()),
                      ),
                      _DrawerSectionLabel(tr(context, 'আর্থিক', 'Finance')),
                      _DrawerItem(
                        icon: Icons.account_balance_wallet_outlined,
                        color: AppColors.finance,
                        title: tr(context, 'আয়-ব্যয়', 'Finance'),
                        onTap: () => _push(context, const FinanceHomeScreen()),
                      ),
                      _DrawerItem(
                        icon: Icons.people_outline,
                        color: AppColors.bakiKhata,
                        title: tr(context, 'বাকি খাতা', 'Baki Khata'),
                        onTap: () => _push(context, const BakiKhataScreen()),
                      ),
                      _DrawerItem(
                        icon: Icons.credit_card_outlined,
                        color: AppColors.loan,
                        title: tr(context, 'ঋণ', 'Loan'),
                        badge: _loanBadge(),
                        onTap: () => _push(context, const LoanScreen()),
                      ),
                      _DrawerItem(
                        icon: Icons.autorenew_rounded,
                        color: AppColors.subscription,
                        title: tr(context, 'সাবস্ক্রিপশন', 'Subscriptions'),
                        badge: _subscriptionBadge(),
                        onTap: () => _push(context, const SubscriptionsScreen()),
                      ),
                      _DrawerSectionLabel(tr(context, 'টুলস', 'Tools')),
                      _DrawerItem(
                        icon: Icons.calculate_outlined,
                        color: AppColors.calculator,
                        title: tr(context, 'ক্যালকুলেটর', 'Calculator'),
                        onTap: () => _push(context, const CalculatorHubScreen()),
                      ),
                      _DrawerItem(
                        icon: Icons.compare_arrows_rounded,
                        color: AppColors.converter,
                        title: tr(context, 'একক রূপান্তর', 'Unit Converter'),
                        onTap: () => _push(context, const UnitConverterScreen()),
                      ),
                      _DrawerItem(
                        icon: Icons.shopping_cart_outlined,
                        color: AppColors.shopping,
                        title: tr(context, 'শপিং তালিকা', 'Shopping List'),
                        badge: _shoppingBadge(),
                        onTap: () => _push(context, const ShoppingListScreen()),
                      ),
                      _DrawerSectionLabel(tr(context, 'ব্যক্তিগত', 'Personal')),
                      _DrawerItem(
                        icon: Icons.spa_outlined,
                        color: AppColors.habits,
                        title: tr(context, 'অভ্যাস', 'Habits'),
                        onTap: () => _push(context, const HabitsScreen()),
                      ),
                      _DrawerItem(
                        icon: Icons.emoji_emotions_outlined,
                        color: AppColors.mood,
                        title: tr(context, 'মেজাজ', 'Mood'),
                        onTap: () => _push(context, const MoodScreen()),
                      ),
                      _DrawerItem(
                        icon: Icons.psychology_outlined,
                        color: AppColors.quiz,
                        title: tr(context, 'দৈনিক কুইজ', 'Daily Quiz'),
                        onTap: () => _push(context, const QuizScreen()),
                      ),
                      _DrawerItem(
                        icon: Icons.lock_outline,
                        color: AppColors.vault,
                        title: tr(context, 'ভল্ট', 'Vault'),
                        onTap: () => _push(context, const VaultScreen()),
                      ),
                      _DrawerItem(
                        icon: Icons.dynamic_feed_rounded,
                        color: AppColors.post,
                        title: tr(context, 'পোস্ট', 'Posts'),
                        badge: _postBadge(),
                        onTap: () => _push(context, const PostsListScreen()),
                      ),
                      _DrawerSectionLabel(tr(context, 'বাকি', 'Misc')),
                      _DrawerItem(
                        icon: Icons.event_outlined,
                        color: AppColors.dateTools,
                        title: tr(context, 'তারিখ টুলস', 'Date Tools'),
                        onTap: () => _push(context, const DateToolsScreen()),
                      ),
                      _DrawerItem(
                        icon: Icons.alarm_outlined,
                        color: AppColors.reminders,
                        title: tr(context, 'রিমাইন্ডার', 'Reminders'),
                        onTap: () => _push(context, const RemindersScreen()),
                      ),
                      _DrawerItem(
                        icon: Icons.mosque_outlined,
                        color: AppColors.prayer,
                        title: tr(context, 'নামাজ', 'Prayer'),
                        onTap: () => _push(context, const PrayerScreen()),
                      ),
                      _DrawerItem(
                        icon: Icons.history_rounded,
                        color: AppColors.primary,
                        title: tr(context, 'হিস্টোরি', 'History'),
                        onTap: () => _push(context, const HistoryScreen()),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _DrawerItem(
                  icon: Icons.person_outline,
                  color: AppColors.primary,
                  title: tr(context, 'প্রোফাইল', 'Profile'),
                  onTap: () => _push(context, const ProfileScreen()),
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  color: scheme.onSurfaceVariant,
                  title: tr(context, 'সেটিংস', 'Settings'),
                  onTap: () => _push(context, const SettingsScreen()),
                ),
              ],
            ),
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required String name,
    required String? email,
    required DateTime? lastBackup,
  }) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : 'U';
    final avatarPath = SettingsService.instance.avatarPath;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
          },
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: avatarPath != null && File(avatarPath).existsSync()
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: avatarPath != null && File(avatarPath).existsSync()
                        ? Image.file(File(avatarPath), fit: BoxFit.cover, width: 48, height: 48)
                        : Text(initial, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (email != null)
                          Text(email, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.save_outlined,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              lastBackup != null
                                  ? tr(context, 'ব্যাকআপ: ${_ago(context, lastBackup)}', 'Backup: ${_ago(context, lastBackup)}')
                                  : tr(context, 'এখনো কোনো ব্যাকআপ নেই', 'No backup yet'),
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Colors.white70, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _ago(BuildContext context, DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return tr(context, 'এখনই', 'just now');
    if (diff.inMinutes < 60) return tr(context, '${diff.inMinutes} মিনিট আগে', '${diff.inMinutes} min ago');
    if (diff.inHours < 24) return tr(context, '${diff.inHours} ঘণ্টা আগে', '${diff.inHours} h ago');
    return tr(context, '${diff.inDays} দিন আগে', '${diff.inDays} d ago');
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  String _todoBadge() {
    final n = Hive.box<TodoItem>('todos').values.where((t) => !t.isCompleted).length;
    return n > 0 ? '$n' : '';
  }

  String _notesBadge() {
    final n = Hive.box<Note>('notes').length;
    return n > 0 ? '$n' : '';
  }

  String _loanBadge() {
    final n = Hive.box<Loan>('loans').length;
    return n > 0 ? '$n' : '';
  }

  String _shoppingBadge() {
    final n = Hive.box<ShoppingItem>('shopping').values.where((s) => !s.checked).length;
    return n > 0 ? '$n' : '';
  }

  String _subscriptionBadge() {
    final n = HiveService.subscriptions.values.where((Subscription s) => s.isActive).length;
    return n > 0 ? '$n' : '';
  }

  String _postBadge() {
    final n = Hive.box<Post>('posts').length;
    return n > 0 ? '$n' : '';
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  final String label;
  const _DrawerSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String badge;
  final VoidCallback onTap;

  const _DrawerItem({required this.icon, required this.color, required this.title, this.badge = '', required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: scheme.onSurface)),
      trailing: badge.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
              child: Text(badge, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
            )
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    );
  }
}

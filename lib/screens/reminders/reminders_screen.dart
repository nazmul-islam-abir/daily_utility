import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/todo_item.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../todo/todo_editor_screen.dart';
import '../loan/loan_detail_screen.dart';

/// One place to see every reminder you've set across the app — a todo due
/// date, a loan instalment — instead of hunting through each section.
/// Medicine, bill, and "important date" reminders all live here too once
/// you create them as a Todo (with recurrence for medicine/bills) — this
/// screen doesn't need its own separate model for those.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'রিমাইন্ডার', 'Reminders'))),
      body: AnimatedBuilder(
        animation: Listenable.merge([HiveService.todos.listenable(), HiveService.loans.listenable()]),
        builder: (context, _) {
          final entries = <_ReminderEntry>[];

          for (final t in HiveService.todos.values) {
            if (!t.isCompleted && t.dueAt != null && t.reminderMinutesBefore != null) {
              entries.add(_ReminderEntry(
                title: t.title,
                subtitle: '${tr(context, 'কাজ', 'Todo')} · ${reminderOffsetLabel(context, t.reminderMinutesBefore!)}',
                fireAt: t.dueAt!.subtract(Duration(minutes: t.reminderMinutesBefore!)),
                dueAt: t.dueAt!,
                color: AppColors.todo,
                icon: Icons.check_circle_outline,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TodoEditorScreen(existing: t))),
              ));
            }
          }
          for (final l in HiveService.loans.values) {
            if (l.nextPaymentDate != null && l.reminderMinutesBefore != null) {
              entries.add(_ReminderEntry(
                title: l.title,
                subtitle: '${tr(context, 'লোন', 'Loan')} · ${reminderOffsetLabel(context, l.reminderMinutesBefore!)}',
                fireAt: l.nextPaymentDate!.subtract(Duration(minutes: l.reminderMinutesBefore!)),
                dueAt: l.nextPaymentDate!,
                color: AppColors.loan,
                icon: Icons.credit_card_outlined,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LoanDetailScreen(loan: l))),
              ));
            }
          }

          entries.sort((a, b) => a.fireAt.compareTo(b.fireAt));

          if (entries.isEmpty) {
            return EmptyState(
              icon: Icons.alarm_outlined,
              title: tr(context, 'কোনো রিমাইন্ডার সেট নেই', 'No reminders set'),
              message: tr(context, 'Todo বা Loan-এ তারিখ ও রিমাইন্ডার যোগ করলে তা এখানে দেখা যাবে।', 'Add a date and reminder to any Todo or Loan — they will show up here.'),
            );
          }

          final now = DateTime.now();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final e = entries[i];
              final passed = e.fireAt.isBefore(now);
              return Card(
                child: ListTile(
                  onTap: e.onTap,
                  leading: CircleAvatar(backgroundColor: e.color.withValues(alpha: 0.14), child: Icon(e.icon, color: e.color)),
                  title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${e.subtitle} · ${tr(context, 'নির্ধারিত:', 'Due:')} ${DateFormat('d MMM, hh:mm a').format(e.dueAt)}'),
                  trailing: passed
                      ? const Icon(Icons.notifications_active, color: AppColors.warning, size: 20)
                      : Text(DateFormat('d MMM').format(e.fireAt), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReminderEntry {
  final String title;
  final String subtitle;
  final DateTime fireAt;
  final DateTime dueAt;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  _ReminderEntry({required this.title, required this.subtitle, required this.fireAt, required this.dueAt, required this.color, required this.icon, required this.onTap});
}

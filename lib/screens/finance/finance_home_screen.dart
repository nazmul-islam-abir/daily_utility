import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/transaction.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'add_transaction_screen.dart';

class FinanceHomeScreen extends StatelessWidget {
  const FinanceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_BD', symbol: '৳', decimalDigits: 0);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: AppColors.bgGradientLight)),
        child: ValueListenableBuilder(
          valueListenable: HiveService.transactions.listenable(),
          builder: (context, Box<MoneyTransaction> box, _) {
            final txs = box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
            final income = txs.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
            final expense = txs.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);
            final balance = income - expense;

            final byCategory = <String, double>{};
            for (final t in txs.where((t) => t.type == 'expense')) {
              byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
            }
            final sortedCats = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.finance, Color(0xFF1E40AF)]),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: [BoxShadow(color: AppColors.finance.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr(context, 'মোট ব্যালেন্স', 'Total Balance'), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5)),
                      const SizedBox(height: 6),
                      AnimatedCounter(value: balance, prefix: '৳', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(child: _miniStat(tr(context, 'আয়', 'Income'), income, Icons.arrow_downward_rounded, true)),
                          const SizedBox(width: 10),
                          Expanded(child: _miniStat(tr(context, 'খরচ', 'Expense'), expense, Icons.arrow_upward_rounded, false)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (sortedCats.isNotEmpty) ...[
                  SectionHeader(tr(context, 'ক্যাটাগরি অনুযায়ী খরচ', 'Spending by category')),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: sortedCats.map((e) {
                          final pct = expense == 0 ? 0.0 : e.value / expense;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    Text(fmt.format(e.value), style: const TextStyle(fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: AppColors.surfaceAlt, color: AppColors.finance),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
                SectionHeader(tr(context, 'সাম্প্রতিক লেনদেন', 'Recent transactions')),
                if (txs.isEmpty)
                  EmptyState(icon: Icons.receipt_long_outlined, title: tr(context, 'কোনো লেনদেন নেই', 'No transactions yet'), message: tr(context, '+ বাটনে চেপে প্রথম লেনদেন যোগ করুন।', 'Tap + to add your first transaction.'))
                else
                  ...txs.map((t) => Dismissible(
                        key: ValueKey(t.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(AppRadius.lg)),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        confirmDismiss: (_) => confirmDelete(context, title: tr(context, 'লেনদেনটি মুছবেন?', 'Delete this transaction?')),
                        onDismissed: (_) => t.delete(),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PressableCard(
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddTransactionScreen(existing: t))),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                GradientIconTile(
                                  icon: t.type == 'income' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                  color: t.type == 'income' ? AppColors.success : AppColors.danger,
                                  size: 42,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t.category, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                      const SizedBox(height: 2),
                                      Text('${DateFormat('d MMM').format(t.date)}${t.note != null && t.note!.isNotEmpty ? ' · ${t.note}' : ''}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${t.type == 'income' ? '+' : '-'}${fmt.format(t.amount)}',
                                  style: TextStyle(fontWeight: FontWeight.w800, color: t.type == 'income' ? AppColors.success : AppColors.danger),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.finance,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddTransactionScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _miniStat(String label, double value, IconData icon, bool isIncome) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 1),
                AnimatedCounter(value: value, prefix: '৳', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../models/loan.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'loan_editor_screen.dart';

const _uuid = Uuid();
final _fmt = NumberFormat.currency(locale: 'en_BD', symbol: '৳', decimalDigits: 0);

class LoanDetailScreen extends StatelessWidget {
  final Loan loan;
  const LoanDetailScreen({super.key, required this.loan});

  Future<void> _addPayment(BuildContext context) async {
    final amountCtrl = TextEditingController(text: loan.monthlyPayment.toStringAsFixed(0));
    final bn = LocaleService.isBangla;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr(ctx, 'কিস্তি প্রদান', 'Add instalment'), style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 14),
            TextField(
              controller: amountCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              decoration: InputDecoration(labelText: tr(ctx, 'পরিমাণ (৳) *', 'Amount (৳) *')),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text.trim());
                if (amount == null || amount <= 0) return;
                loan.payments.add(LoanPayment(id: _uuid.v4(), amount: amount, date: DateTime.now()));

                if (loan.nextPaymentDate != null) {
                  final next = DateTime(loan.nextPaymentDate!.year, loan.nextPaymentDate!.month + 1, loan.nextPaymentDate!.day);
                  await NotificationService.cancel(loan.notificationId);
                  loan.notificationId = null;
                  loan.nextPaymentDate = next;
                  if (loan.reminderMinutesBefore != null) {
                    loan.notificationId = await NotificationService.scheduleReminder(
                      idKey: 'loan_${loan.id}',
                      title: bn ? 'লোন কিস্তি: ${loan.title}' : 'Loan instalment: ${loan.title}',
                      body: bn ? 'পরবর্তী কিস্তি ${DateFormat('d MMM').format(next)}' : 'Next instalment ${DateFormat('d MMM').format(next)}',
                      fireAt: next.subtract(Duration(minutes: loan.reminderMinutesBefore!)),
                    );
                  }
                }
                await loan.save();
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: Text(tr(ctx, 'সংরক্ষণ করুন', 'Save')),
            ),
          ],
        ),
      ),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context, 'কিস্তি রেকর্ড হয়েছে', 'Instalment recorded'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: HiveService.loans.listenable(),
      builder: (context, _) {
        final remaining = loan.remainingBalance;
        final progress = loan.principal == 0 ? 0.0 : (1 - remaining / loan.principal).clamp(0.0, 1.0);
        final payments = loan.payments.toList()..sort((a, b) => b.date.compareTo(a.date));

        return Scaffold(
          appBar: AppBar(
            title: Text(loan.title),
            actions: [
              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LoanEditorScreen(existing: loan)))),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await confirmDelete(context, title: tr(context, 'লোনটি মুছবেন?', 'Delete this loan?'));
                  if (ok) {
                    await NotificationService.cancel(loan.notificationId);
                    await loan.delete();
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.loan,
            onPressed: () => _addPayment(context),
            icon: const Icon(Icons.add),
            label: Text(tr(context, 'কিস্তি যোগ করুন', 'Add instalment')),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.loan, borderRadius: BorderRadius.circular(AppRadius.lg)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr(context, 'বাকি আছে', 'Remaining'), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(_fmt.format(remaining), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.white24, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(tr(context, '${(progress * 100).round()}% পরিশোধ হয়েছে · মোট ${_fmt.format(loan.principal)}', '${(progress * 100).round()}% paid · Total ${_fmt.format(loan.principal)}'), style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: StatPill(label: tr(context, 'মাসিক কিস্তি', 'Monthly payment'), value: _fmt.format(loan.monthlyPayment), color: AppColors.loan)),
                  const SizedBox(width: 10),
                  Expanded(child: StatPill(label: tr(context, 'সুদের হার', 'Interest rate'), value: '${loan.interestRatePercent}%', color: AppColors.loan)),
                ],
              ),
              if (loan.nextPaymentDate != null) ...[
                const SizedBox(height: 10),
                StatPill(label: tr(context, 'পরবর্তী কিস্তি', 'Next instalment'), value: DateFormat('d MMMM y').format(loan.nextPaymentDate!), color: AppColors.warning),
              ],
              SectionHeader(tr(context, 'পেমেন্ট ইতিহাস', 'Payment history')),
              if (payments.isEmpty)
                EmptyState(icon: Icons.payments_outlined, title: tr(context, 'কোনো কিস্তি দেওয়া হয়নি', 'No instalments yet'), message: tr(context, 'নিচের বাটনে চেপে প্রথম কিস্তি যোগ করুন।', 'Add your first instalment using the button below.'))
              else
                ...payments.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        tileColor: scheme.surface,
                        textColor: scheme.onSurface,
                        iconColor: AppColors.success,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: BorderSide.none),
                        leading: const Icon(Icons.check_circle, color: AppColors.success),
                        title: Text(_fmt.format(p.amount), style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)),
                        subtitle: Text(DateFormat('d MMMM y').format(p.date), style: TextStyle(color: scheme.onSurfaceVariant)),
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }
}

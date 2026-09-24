import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/loan.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'loan_detail_screen.dart';
import 'loan_editor_screen.dart';

final _fmt = NumberFormat.currency(locale: 'en_BD', symbol: '৳', decimalDigits: 0);

class LoanScreen extends StatelessWidget {
  const LoanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'লোন', 'Loan'))),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.loan,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoanEditorScreen())),
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder(
        valueListenable: HiveService.loans.listenable(),
        builder: (context, Box<Loan> box, _) {
          final loans = box.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (loans.isEmpty) {
            return EmptyState(icon: Icons.credit_card_outlined, title: tr(context, 'কোনো লোন যোগ করা হয়নি', 'No loans yet'), message: tr(context, '+ বাটনে চেপে একটি লোন ট্র্যাক করা শুরু করুন।', 'Tap + to start tracking a loan.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            itemCount: loans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final loan = loans[i];
              final progress = loan.principal == 0 ? 0.0 : (1 - loan.remainingBalance / loan.principal).clamp(0.0, 1.0);
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LoanDetailScreen(loan: loan))),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(loan.title, style: Theme.of(context).textTheme.titleMedium)),
                            Text(_fmt.format(loan.remainingBalance), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.loan)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: AppColors.surfaceAlt, color: AppColors.loan),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loan.nextPaymentDate != null ? tr(context, 'পরবর্তী কিস্তি: ${DateFormat('d MMM y').format(loan.nextPaymentDate!)}', 'Next instalment: ${DateFormat('d MMM y').format(loan.nextPaymentDate!)}') : tr(context, 'মাসিক কিস্তি ${_fmt.format(loan.monthlyPayment)}', 'Monthly ${_fmt.format(loan.monthlyPayment)}'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

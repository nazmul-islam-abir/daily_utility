import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../models/baki_khata.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

const _uuid = Uuid();
final _fmt = NumberFormat.currency(locale: 'en_BD', symbol: '৳', decimalDigits: 0);

class PersonDetailScreen extends StatelessWidget {
  final Person person;
  const PersonDetailScreen({super.key, required this.person});

  Future<void> _addEntry(BuildContext context, String direction) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              direction == 'gave'
                  ? tr(ctx, '${person.name}-কে দিলেন', 'You gave ${person.name}')
                  : tr(ctx, '${person.name} থেকে পেলেন', 'You got from ${person.name}'),
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: amountCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              decoration: InputDecoration(labelText: tr(ctx, 'পরিমাণ (৳) *', 'Amount (৳) *')),
            ),
            const SizedBox(height: 12),
            TextField(controller: noteCtrl, decoration: InputDecoration(labelText: tr(ctx, 'নোট (ঐচ্ছিক)', 'Note (optional)'))),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: direction == 'gave' ? AppColors.danger : AppColors.success),
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text.trim());
                if (amount == null || amount <= 0) return;
                final entry = LedgerEntry(
                  id: _uuid.v4(),
                  personId: person.id,
                  amount: amount,
                  direction: direction,
                  note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                  date: DateTime.now(),
                );
                await HiveService.ledger.put(entry.id, entry);
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: Text(tr(ctx, 'সংরক্ষণ করুন', 'Save')),
            ),
          ],
        ),
      ),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            direction == 'gave'
                ? tr(context, 'লেনদেন যোগ হয়েছে (দিলেন)', 'Entry added (you gave)')
                : tr(context, 'লেনদেন যোগ হয়েছে (পেলেন)', 'Entry added (you got)'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      appBar: AppBar(title: Text(person.name)),
      body: ValueListenableBuilder(
        valueListenable: HiveService.ledger.listenable(),
        builder: (context, Box<LedgerEntry> box, _) {
          final entries = box.values.where((e) => e.personId == person.id).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          final balance = entries.fold(0.0, (s, e) => s + e.signedAmount);
          final theyOweYou = balance >= 0;

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: (theyOweYou ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          theyOweYou
                              ? tr(context, 'আপনি পাবেন', 'You will receive')
                              : tr(context, 'আপনি দেবেন', 'You will pay'),
                          style: TextStyle(color: theyOweYou ? AppColors.success : AppColors.danger, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (theyOweYou ? AppColors.success : AppColors.danger).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${entries.length} ${tr(context, 'টি', '')}'.trim(),
                            style: TextStyle(
                              color: theyOweYou ? AppColors.success : AppColors.danger,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fmt.format(balance.abs()),
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: theyOweYou ? AppColors.success : AppColors.danger),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _addEntry(context, 'gave'),
                        icon: const Icon(Icons.arrow_upward_rounded, size: 18, color: AppColors.danger),
                        label: Text(tr(context, 'দিলেন', 'You gave')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _addEntry(context, 'got'),
                        icon: const Icon(Icons.arrow_downward_rounded, size: 18, color: AppColors.success),
                        label: Text(tr(context, 'পেলেন', 'You got')),
                      ),
                    ),
                  ],
                ),
              ),
              SectionHeader(
                tr(context, 'লেনদেনের ইতিহাস', 'Transaction history'),
                trailing: Text(
                  tr(context, '${entries.length} টি এন্ট্রি', '${entries.length} entries'),
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: entries.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: tr(context, 'কোনো লেনদেন নেই', 'No transactions yet'),
                        message: tr(context, 'উপরের বাটন থেকে যোগ করুন।', 'Add one using the buttons above.'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final e = entries[i];
                          final gave = e.direction == 'gave';
                          return Dismissible(
                            key: ValueKey(e.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(AppRadius.md)),
                              child: const Icon(Icons.delete_outline, color: Colors.white),
                            ),
                            confirmDismiss: (_) => confirmDelete(context, title: tr(context, 'এন্ট্রিটি মুছবেন?', 'Delete this entry?')),
                            onDismissed: (_) => e.delete(),
                            child: ListTile(
                              tileColor: scheme.surface,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: BorderSide.none),
                              leading: Icon(gave ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: gave ? AppColors.danger : AppColors.success),
                              title: Text(
                                tr(
                                  context,
                                  '${gave ? '+ দিলেন' : '- পেলেন'} ${_fmt.format(e.amount)}',
                                  '${gave ? '+ You gave' : '- You got'} ${_fmt.format(e.amount)}',
                                ),
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                '${DateFormat('d MMM y').format(e.date)}${e.note != null ? ' · ${e.note}' : ''}',
                                style: TextStyle(color: scheme.onSurfaceVariant),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

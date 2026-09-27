import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../models/baki_khata.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'person_detail_screen.dart';

const _uuid = Uuid();
final _fmt = NumberFormat.currency(locale: 'en_BD', symbol: '৳', decimalDigits: 0);

class BakiKhataScreen extends StatelessWidget {
  const BakiKhataScreen({super.key});

  Future<void> _addPerson(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr(ctx, 'নতুন ব্যক্তি', 'New person'), style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 14),
            TextField(controller: nameCtrl, autofocus: true, decoration: InputDecoration(labelText: tr(ctx, 'নাম *', 'Name *'))),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: tr(ctx, 'ফোন নম্বর (ঐচ্ছিক)', 'Phone (optional)'))),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final person = Person(id: _uuid.v4(), name: name, phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(), createdAt: DateTime.now());
                await HiveService.people.put(person.id, person);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(tr(ctx, 'যোগ করুন', 'Add')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      appBar: AppBar(
        title: Text(tr(context, 'বাকি খাতা', 'Baki Khata')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.bakiKhata,
        onPressed: () => _addPerson(context),
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: ValueListenableBuilder(
        valueListenable: HiveService.people.listenable(),
        builder: (context, Box<Person> peopleBox, _) {
          final people = peopleBox.values.toList()..sort((a, b) => a.name.compareTo(b.name));
          return ValueListenableBuilder(
            valueListenable: HiveService.ledger.listenable(),
            builder: (context, Box<LedgerEntry> ledgerBox, __) {
              double totalReceivable = 0, totalPayable = 0;
              final balances = <String, double>{};
              int totalEntries = 0;
              for (final p in people) {
                final entries = ledgerBox.values.where((e) => e.personId == p.id);
                totalEntries += entries.length;
                final bal = entries.fold(0.0, (s, e) => s + e.signedAmount);
                balances[p.id] = bal;
                if (bal >= 0) {
                  totalReceivable += bal;
                } else {
                  totalPayable += -bal;
                }
              }

              if (people.isEmpty) {
                return EmptyState(
                  icon: Icons.people_outline,
                  title: tr(context, 'কোনো ব্যক্তি যোগ করা হয়নি', 'No people yet'),
                  message: tr(context, '+ বাটনে চেপে প্রথম ব্যক্তি যোগ করুন।', 'Tap + to add your first person.'),
                );
              }

              // Bilingual "X baki khata info" header so users see how many
              // people + ledger entries are stored here.
              final peopleCount = people.length;
              final peopleLabelBn = '$peopleCount জন ব্যক্তি · $totalEntries টি লেনদেন';
              final peopleLabelEn = '$peopleCount people · $totalEntries entries';

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.people_alt_rounded, size: 16, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(
                          tr(context, peopleLabelBn, peopleLabelEn),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(child: StatPill(label: tr(context, 'মোট পাবেন', 'You will receive'), value: _fmt.format(totalReceivable), color: AppColors.success)),
                      const SizedBox(width: 10),
                      Expanded(child: StatPill(label: tr(context, 'মোট দেবেন', 'You will pay'), value: _fmt.format(totalPayable), color: AppColors.danger)),
                    ],
                  ),
                  SectionHeader(tr(context, 'সবাই', 'Everyone')),
                  ...people.map((p) {
                    final bal = balances[p.id] ?? 0;
                    final theyOweYou = bal >= 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PersonDetailScreen(person: p))),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.bakiKhata.withValues(alpha: 0.14),
                            child: Text(
                              p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: AppColors.bakiKhata, fontWeight: FontWeight.w800),
                            ),
                          ),
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            bal == 0
                                ? tr(context, 'হিসাব মিটে গেছে', 'Settled up')
                                : (theyOweYou
                                    ? tr(context, 'আপনি পাবেন', 'You will receive')
                                    : tr(context, 'আপনি দেবেন', 'You will pay')),
                          ),
                          trailing: Text(
                            _fmt.format(bal.abs()),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: bal == 0
                                  ? scheme.onSurfaceVariant
                                  : (theyOweYou ? AppColors.success : AppColors.danger),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

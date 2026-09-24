import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../models/history_entry.dart';
import '../../models/transaction.dart';
import '../../services/history_service.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

const _uuid = Uuid();

class AddTransactionScreen extends StatefulWidget {
  final MoneyTransaction? existing;
  const AddTransactionScreen({super.key, this.existing});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = 'expense';
  String _category = kExpenseCategories.first;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _amountCtrl.text = e.amount == e.amount.roundToDouble() ? e.amount.toStringAsFixed(0) : e.amount.toString();
      _noteCtrl.text = e.note ?? '';
      _type = e.type;
      _category = e.category;
      _date = e.date;
    }
  }

  List<String> get _categories => _type == 'income' ? kIncomeCategories : kExpenseCategories;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LocaleService.isBangla ? 'সঠিক পরিমাণ লিখুন' : 'Please enter a valid amount')));
      return;
    }
    final isNew = widget.existing == null;
    final tx = widget.existing ?? MoneyTransaction(id: _uuid.v4(), type: _type, amount: amount, category: _category, date: _date, createdAt: DateTime.now());
    tx
      ..type = _type
      ..amount = amount
      ..category = _category
      ..note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim()
      ..date = _date;

    final bn = LocaleService.isBangla;
    if (isNew) {
      await HiveService.transactions.put(tx.id, tx);
      await HistoryService.record(
        kind: HistoryKind.finance,
        title: tx.type == 'income' ? (bn ? 'আয়' : 'Income') : (bn ? 'খরচ' : 'Expense'),
        subtitle: '${tx.category}${tx.note == null ? '' : ' · ${tx.note}'}',
        result: '${NumberFormat('#,##0.##').format(tx.amount)} ৳',
        inputs: bn
            ? {'ধরন': tx.type, 'ক্যাটাগরি': tx.category, 'পরিমাণ': tx.amount.toString(), 'তারিখ': DateFormat('d MMM y').format(tx.date)}
            : {'Type': tx.type, 'Category': tx.category, 'Amount': tx.amount.toString(), 'Date': DateFormat('d MMM y').format(tx.date)},
      );
    } else {
      await tx.save();
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? tr(context, 'নতুন লেনদেন', 'New transaction') : tr(context, 'লেনদেন সম্পাদনা', 'Edit transaction'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text(tr(context, 'খরচ', 'Expense')),
                    selected: _type == 'expense',
                    selectedColor: AppColors.danger.withValues(alpha: 0.16),
                    onSelected: (_) => setState(() {
                      _type = 'expense';
                      _category = kExpenseCategories.first;
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: Text(tr(context, 'আয়', 'Income')),
                    selected: _type == 'income',
                    selectedColor: AppColors.success.withValues(alpha: 0.16),
                    onSelected: (_) => setState(() {
                      _type = 'income';
                      _category = kIncomeCategories.first;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              decoration: InputDecoration(labelText: tr(context, 'পরিমাণ (৳) *', 'Amount (৳) *')),
            ),
            SectionHeader(tr(context, 'ক্যাটাগরি', 'Category')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories
                  .map((c) => ChoiceChip(label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = c)))
                  .toList(),
            ),
            SectionHeader(tr(context, 'তারিখ', 'Date')),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(DateFormat('d MMMM y').format(_date)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(labelText: tr(context, 'নোট (ঐচ্ছিক)', 'Note (optional)')),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 28),
            FilledButton(onPressed: _save, child: Text(tr(context, 'সংরক্ষণ করুন', 'Save'))),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../models/loan.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/common_widgets.dart';

const _uuid = Uuid();

class LoanEditorScreen extends StatefulWidget {
  final Loan? existing;
  const LoanEditorScreen({super.key, this.existing});

  @override
  State<LoanEditorScreen> createState() => _LoanEditorScreenState();
}

class _LoanEditorScreenState extends State<LoanEditorScreen> {
  final _titleCtrl = TextEditingController();
  final _principalCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _monthlyCtrl = TextEditingController();
  final _termCtrl = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _nextPaymentDate;
  int? _reminderMinutes;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _principalCtrl.text = e.principal.toStringAsFixed(0);
      _rateCtrl.text = e.interestRatePercent.toString();
      _monthlyCtrl.text = e.monthlyPayment.toStringAsFixed(0);
      _termCtrl.text = e.termMonths?.toString() ?? '';
      _startDate = e.startDate;
      _nextPaymentDate = e.nextPaymentDate;
      _reminderMinutes = e.reminderMinutesBefore;
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _nextPaymentDate) ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 15),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _nextPaymentDate = picked;
      }
    });
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final principal = double.tryParse(_principalCtrl.text.trim());
    final monthly = double.tryParse(_monthlyCtrl.text.trim());
    if (title.isEmpty || principal == null || principal <= 0 || monthly == null || monthly <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LocaleService.isBangla ? 'নাম, মূল অর্থ ও মাসিক কিস্তি সঠিকভাবে দিন' : 'Please provide a title, principal, and monthly payment')));
      return;
    }
    final isNew = widget.existing == null;
    final loan = widget.existing ??
        Loan(
          id: _uuid.v4(),
          title: title,
          principal: principal,
          interestRatePercent: 0,
          monthlyPayment: monthly,
          startDate: _startDate,
          createdAt: DateTime.now(),
        );
    loan
      ..title = title
      ..principal = principal
      ..interestRatePercent = double.tryParse(_rateCtrl.text.trim()) ?? 0
      ..monthlyPayment = monthly
      ..startDate = _startDate
      ..termMonths = int.tryParse(_termCtrl.text.trim())
      ..nextPaymentDate = _nextPaymentDate
      ..reminderMinutesBefore = _reminderMinutes;

    final bn = LocaleService.isBangla;
    await NotificationService.cancel(loan.notificationId);
    loan.notificationId = null;
    if (_nextPaymentDate != null && _reminderMinutes != null) {
      loan.notificationId = await NotificationService.scheduleReminder(
        idKey: 'loan_${loan.id}',
        title: bn ? 'লোন কিস্তি: ${loan.title}' : 'Loan instalment: ${loan.title}',
        body: bn ? 'পরবর্তী কিস্তি ${DateFormat('d MMM').format(_nextPaymentDate!)}' : 'Next instalment ${DateFormat('d MMM').format(_nextPaymentDate!)}',
        fireAt: _nextPaymentDate!.subtract(Duration(minutes: _reminderMinutes!)),
      );
    }

    if (isNew) {
      await HiveService.loans.put(loan.id, loan);
    } else {
      await loan.save();
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? tr(context, 'নতুন লোন', 'New loan') : tr(context, 'লোন সম্পাদনা', 'Edit loan'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            TextField(controller: _titleCtrl, autofocus: true, decoration: InputDecoration(labelText: tr(context, 'লোনের নাম *', 'Loan name *'), hintText: tr(context, 'যেমন: হোম লোন', 'e.g. Home loan'))),
            const SizedBox(height: 14),
            TextField(controller: _principalCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: tr(context, 'মোট লোনের পরিমাণ (৳) *', 'Total loan amount (৳) *'))),
            const SizedBox(height: 14),
            TextField(controller: _rateCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: tr(context, 'সুদের হার (%/বছর)', 'Interest rate (%/year)'))),
            const SizedBox(height: 14),
            TextField(controller: _monthlyCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: tr(context, 'মাসিক কিস্তি (৳) *', 'Monthly payment (৳) *'))),
            const SizedBox(height: 14),
            TextField(controller: _termCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr(context, 'মেয়াদ (মাস, ঐচ্ছিক)', 'Term (months, optional)'))),
            SectionHeader(tr(context, 'শুরুর তারিখ', 'Start date')),
            OutlinedButton.icon(
              onPressed: () => _pickDate(isStart: true),
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(DateFormat('d MMMM y').format(_startDate)),
            ),
            SectionHeader(tr(context, 'পরবর্তী কিস্তির তারিখ (ঐচ্ছিক)', 'Next instalment date (optional)')),
            OutlinedButton.icon(
              onPressed: () => _pickDate(isStart: false),
              icon: const Icon(Icons.event_outlined, size: 18),
              label: Text(_nextPaymentDate == null ? tr(context, 'তারিখ নির্বাচন করুন', 'Pick a date') : DateFormat('d MMMM y').format(_nextPaymentDate!)),
            ),
            if (_nextPaymentDate != null) ...[
              SectionHeader(tr(context, 'রিমাইন্ডার (ঐচ্ছিক)', 'Reminder (optional)')),
              ReminderPicker(value: _reminderMinutes, onChanged: (v) => setState(() => _reminderMinutes = v)),
            ],
            const SizedBox(height: 28),
            FilledButton(onPressed: _save, child: Text(tr(context, 'সংরক্ষণ করুন', 'Save'))),
          ],
        ),
      ),
    );
  }
}

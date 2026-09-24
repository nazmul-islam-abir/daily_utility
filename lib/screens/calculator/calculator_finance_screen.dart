import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

final _fmt = NumberFormat.currency(locale: 'en_BD', symbol: '৳', decimalDigits: 2);

class CalculatorFinanceScreen extends StatelessWidget {
  const CalculatorFinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tabs = <_CalcTab>[
      _CalcTab('EMI / লোন', 'EMI / Loan', const EmiCalculator()),
      _CalcTab('সঞ্চয়', 'Savings', const SavingsCalculator()),
      _CalcTab('সরল সুদ', 'Simple Interest', const SimpleInterestCalculator()),
      _CalcTab('VAT', 'VAT', const VatCalculator()),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr(context, 'আর্থিক ক্যালকুলেটর', 'Finance Calculator')),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final t in tabs) Tab(text: tr(context, t.bn, t.en))],
          ),
        ),
        body: TabBarView(
          children: [
            for (final t in tabs)
              SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), child: t.child),
          ],
        ),
      ),
    );
  }
}

class _CalcTab {
  final String bn;
  final String en;
  final Widget child;
  _CalcTab(this.bn, this.en, this.child);
}

class EmiCalculator extends StatefulWidget {
  const EmiCalculator({super.key});
  @override
  State<EmiCalculator> createState() => _EmiCalculatorState();
}

class _EmiCalculatorState extends State<EmiCalculator> {
  final _principalCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _yearsCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final p = double.tryParse(_principalCtrl.text);
    final annualRate = double.tryParse(_rateCtrl.text);
    final years = double.tryParse(_yearsCtrl.text);
    String? result;
    if (p != null && annualRate != null && years != null && years > 0) {
      final n = years * 12;
      final r = annualRate / 12 / 100;
      double emi;
      if (r == 0) {
        emi = p / n;
      } else {
        final factor = _pow(1 + r, n.round());
        emi = p * r * factor / (factor - 1);
      }
      final totalPay = emi * n;
      final totalInterest = totalPay - p;
      result = tr(context, 'মাসিক কিস্তি: ${_fmt.format(emi)}\nমোট সুদ: ${_fmt.format(totalInterest)}\nমোট পরিশোধ: ${_fmt.format(totalPay)}', 'Monthly EMI: ${_fmt.format(emi)}\nTotal interest: ${_fmt.format(totalInterest)}\nTotal payment: ${_fmt.format(totalPay)}');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _principalCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: tr(context, 'লোনের পরিমাণ (৳)', 'Loan amount (৳)')),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _rateCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr(context, 'সুদের হার (%/বছর)', 'Interest rate (%/year)')),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _yearsCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr(context, 'মেয়াদ (বছর)', 'Tenure (years)')),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        if (result != null) ResultText(result),
      ],
    );
  }

  double _pow(double base, int exp) {
    double r = 1;
    for (int i = 0; i < exp; i++) {
      r *= base;
    }
    return r;
  }
}

class SavingsCalculator extends StatefulWidget {
  const SavingsCalculator({super.key});
  @override
  State<SavingsCalculator> createState() => _SavingsCalculatorState();
}

class _SavingsCalculatorState extends State<SavingsCalculator> {
  final _monthlyCtrl = TextEditingController();
  final _rateCtrl = TextEditingController(text: '6');
  final _yearsCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final monthly = double.tryParse(_monthlyCtrl.text);
    final annualRate = double.tryParse(_rateCtrl.text) ?? 0;
    final years = double.tryParse(_yearsCtrl.text);
    String? result;
    if (monthly != null && years != null && years > 0) {
      final n = (years * 12).round();
      final r = annualRate / 12 / 100;
      double future = 0;
      for (int i = 0; i < n; i++) {
        future = (future + monthly) * (1 + r);
      }
      final deposited = monthly * n;
      result = tr(context, 'জমার শেষে মোট: ${_fmt.format(future)}\nআপনার জমা: ${_fmt.format(deposited)}\nমুনাফা: ${_fmt.format(future - deposited)}', 'Maturity value: ${_fmt.format(future)}\nYou deposited: ${_fmt.format(deposited)}\nInterest earned: ${_fmt.format(future - deposited)}');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _monthlyCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: tr(context, 'মাসিক জমা (৳)', 'Monthly deposit (৳)')),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _rateCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr(context, 'বার্ষিক মুনাফা হার (%)', 'Annual interest rate (%)')),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _yearsCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr(context, 'মেয়াদ (বছর)', 'Tenure (years)')),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        if (result != null) ResultText(result),
      ],
    );
  }
}

class SimpleInterestCalculator extends StatefulWidget {
  const SimpleInterestCalculator({super.key});
  @override
  State<SimpleInterestCalculator> createState() => _SimpleInterestCalculatorState();
}

class _SimpleInterestCalculatorState extends State<SimpleInterestCalculator> {
  final _principalCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _yearsCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final p = double.tryParse(_principalCtrl.text);
    final r = double.tryParse(_rateCtrl.text);
    final t = double.tryParse(_yearsCtrl.text);
    String? result;
    if (p != null && r != null && t != null) {
      final interest = p * r * t / 100;
      result = tr(context, 'সুদ: ${_fmt.format(interest)} · মোট: ${_fmt.format(p + interest)}', 'Interest: ${_fmt.format(interest)} · Total: ${_fmt.format(p + interest)}');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _principalCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr(context, 'আসল (৳)', 'Principal (৳)')),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _rateCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr(context, 'হার (%/বছর)', 'Rate (%/year)')),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _yearsCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: tr(context, 'সময় (বছর)', 'Time (years)')),
          onChanged: (_) => setState(() {}),
        ),
        if (result != null) ResultText(result),
      ],
    );
  }
}

class VatCalculator extends StatefulWidget {
  const VatCalculator({super.key});
  @override
  State<VatCalculator> createState() => _VatCalculatorState();
}

class _VatCalculatorState extends State<VatCalculator> {
  final _amountCtrl = TextEditingController();
  double _vatRate = 15;
  bool _amountIncludesVat = false;

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountCtrl.text);
    String? result;
    if (amount != null) {
      if (_amountIncludesVat) {
        final base = amount / (1 + _vatRate / 100);
        result = tr(context, 'মূল দাম: ${_fmt.format(base)}\nVAT: ${_fmt.format(amount - base)}', 'Base price: ${_fmt.format(base)}\nVAT: ${_fmt.format(amount - base)}');
      } else {
        final vat = amount * _vatRate / 100;
        result = tr(context, 'VAT: ${_fmt.format(vat)}\nমোট: ${_fmt.format(amount + vat)}', 'VAT: ${_fmt.format(vat)}\nTotal: ${_fmt.format(amount + vat)}');
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: tr(context, 'পরিমাণ (৳)', 'Amount (৳)')),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(tr(context, 'VAT হার:', 'VAT rate:'), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: _vatRate,
                min: 0,
                max: 25,
                divisions: 25,
                activeColor: AppColors.calculator,
                label: '${_vatRate.round()}%',
                onChanged: (v) => setState(() => _vatRate = v),
              ),
            ),
            Text('${_vatRate.round()}%'),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: _amountIncludesVat,
          activeColor: AppColors.calculator,
          title: Text(tr(context, 'পরিমাণে VAT অন্তর্ভুক্ত আছে', 'Amount includes VAT'), style: const TextStyle(fontSize: 13.5)),
          onChanged: (v) => setState(() => _amountIncludesVat = v),
        ),
        if (result != null) ResultText(result),
      ],
    );
  }
}

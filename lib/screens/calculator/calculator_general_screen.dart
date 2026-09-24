import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/history_entry.dart';
import '../../services/history_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class CalculatorGeneralScreen extends StatelessWidget {
  const CalculatorGeneralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tabs = <_CalcTab>[
      _CalcTab('বেসিক', 'Basic', const BasicCalculator()),
      _CalcTab('শতাংশ', 'Percent', const PercentageCalculator()),
      _CalcTab('ছাড়', 'Discount', const DiscountCalculator()),
      _CalcTab('বকশিশ', 'Tip', const TipCalculator()),
      _CalcTab('দৈর্ঘ্য', 'Length', const LengthConverter()),
      _CalcTab('ওজন', 'Weight', const WeightConverter()),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr(context, 'সাধারণ ক্যালকুলেটর', 'General Calculator')),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final t in tabs) Tab(text: tr(context, t.bn, t.en))],
          ),
        ),
        body: TabBarView(
          children: [for (final t in tabs) SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), child: t.child)],
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

// ── Basic 4-function calculator ────────────────────────────────────────────
class BasicCalculator extends StatefulWidget {
  const BasicCalculator({super.key});
  @override
  State<BasicCalculator> createState() => _BasicCalculatorState();
}

class _BasicCalculatorState extends State<BasicCalculator> {
  String _expression = '';
  double _acc = 0;
  String? _pendingOp;
  bool _freshResult = false;

  void _digit(String d) {
    setState(() {
      if (_freshResult) {
        _expression = '';
        _freshResult = false;
      }
      _expression += d;
    });
  }

  void _op(String op) {
    if (_expression.isEmpty && _pendingOp != null) {
      setState(() => _pendingOp = op);
      return;
    }
    final current = double.tryParse(_expression) ?? 0;
    setState(() {
      if (_pendingOp == null) {
        _acc = current;
      } else {
        _acc = _apply(_acc, current, _pendingOp!);
      }
      _pendingOp = op;
      _expression = '';
      _freshResult = false;
    });
  }

  double _apply(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        return b == 0 ? 0 : a / b;
      default:
        return b;
    }
  }

  void _equals() {
    if (_pendingOp == null) return;
    final current = double.tryParse(_expression) ?? 0;
    final pendingOp = _pendingOp!;
    setState(() {
      _acc = _apply(_acc, current, pendingOp);
      _pendingOp = null;
      _expression = _formatNum(_acc);
      _freshResult = true;
    });
    final bn = LocaleService.isBangla;
    HistoryService.record(
      kind: HistoryKind.calculator,
      title: bn ? 'বেসিক ক্যালকুলেটর' : 'Basic Calculator',
      subtitle: bn ? 'হিসাব সম্পন্ন' : 'Calculation complete',
      result: '= ${_formatNum(_acc)}',
      inputs: {
        bn ? 'অপারেশন' : 'Operation': pendingOp,
        bn ? 'ফলাফল' : 'Result': _formatNum(_acc),
      },
    );
  }

  void _clear() {
    setState(() {
      _expression = '';
      _acc = 0;
      _pendingOp = null;
      _freshResult = false;
    });
  }

  String _formatNum(double n) => n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final display = _expression.isEmpty ? (_pendingOp != null ? _formatNum(_acc) : '0') : _expression;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
          alignment: Alignment.centerRight,
          child: Text(display, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: scheme.onSurface), maxLines: 1),
        ),
        const SizedBox(height: 10),
        _padRow(['7', '8', '9', '÷']),
        _padRow(['4', '5', '6', '×']),
        _padRow(['1', '2', '3', '-']),
        _padRow(['C', '0', '=', '+']),
      ],
    );
  }

  Widget _padRow(List<String> keys) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: keys.map((k) {
          final isOp = ['+', '-', '×', '÷', '='].contains(k);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isOp ? AppColors.calculator.withValues(alpha: 0.1) : null,
                    side: BorderSide.none,
                  ),
                  onPressed: () {
                    if (k == 'C') return _clear();
                    if (k == '=') return _equals();
                    if (['+', '-', '×', '÷'].contains(k)) return _op(k);
                    if (k == '.') {
                      if (!_expression.contains('.')) _digit(k);
                      return;
                    }
                    _digit(k);
                  },
                  child: Text(k, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isOp ? AppColors.calculator : scheme.onSurface)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Percentage ──────────────────────────────────────────────────────────────
class PercentageCalculator extends StatefulWidget {
  const PercentageCalculator({super.key});
  @override
  State<PercentageCalculator> createState() => _PercentageCalculatorState();
}

class _PercentageCalculatorState extends State<PercentageCalculator> {
  final _pctCtrl = TextEditingController();
  final _valCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final pct = double.tryParse(_pctCtrl.text);
    final val = double.tryParse(_valCtrl.text);
    final result = (pct != null && val != null) ? (pct / 100) * val : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: TextField(controller: _pctCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr(context, 'শতাংশ (%)', 'Percent (%)')), onChanged: (_) => setState(() {}))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(tr(context, 'এর', 'of'))),
            Expanded(child: TextField(controller: _valCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr(context, 'মান', 'Value')), onChanged: (_) => setState(() {}))),
          ],
        ),
        if (result != null) ...[
          ResultText('= ${NumberFormat('#,##0.##').format(result)}'),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.history, size: 16),
              label: Text(tr(context, 'সংরক্ষণ', 'Save')),
              onPressed: () {
                final bn = LocaleService.isBangla;
                HistoryService.record(
                  kind: HistoryKind.calculator,
                  title: bn ? 'শতাংশ ক্যালকুলেটর' : 'Percent Calculator',
                  subtitle: bn ? '${_pctCtrl.text}% এর ${_valCtrl.text}' : '${_pctCtrl.text}% of ${_valCtrl.text}',
                  result: NumberFormat('#,##0.##').format(result),
                  inputs: {
                    bn ? 'শতাংশ' : 'Percent': _pctCtrl.text,
                    bn ? 'মান' : 'Value': _valCtrl.text,
                    bn ? 'ফলাফল' : 'Result': NumberFormat('#,##0.##').format(result),
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

// ── Discount ──────────────────────────────────────────────────────────────
class DiscountCalculator extends StatefulWidget {
  const DiscountCalculator({super.key});
  @override
  State<DiscountCalculator> createState() => _DiscountCalculatorState();
}

class _DiscountCalculatorState extends State<DiscountCalculator> {
  final _priceCtrl = TextEditingController();
  final _pctCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(_priceCtrl.text);
    final pct = double.tryParse(_pctCtrl.text);
    final fmt = NumberFormat.currency(locale: 'en_BD', symbol: '৳', decimalDigits: 2);
    String? result;
    String? savedTxt;
    if (price != null && pct != null) {
      final saved = price * pct / 100;
      final finalPrice = price - saved;
      result = tr(context, 'বাঁচলো ${fmt.format(saved)} · দাম দাঁড়ালো ${fmt.format(finalPrice)}', 'You saved ${fmt.format(saved)} · Final price ${fmt.format(finalPrice)}');
      savedTxt = fmt.format(saved);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: TextField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr(context, 'দাম (৳)', 'Price (৳)')), onChanged: (_) => setState(() {}))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _pctCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr(context, 'ছাড় (%)', 'Discount (%)')), onChanged: (_) => setState(() {}))),
          ],
        ),
        if (result != null) ...[
          ResultText(result),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.history, size: 16),
              label: Text(tr(context, 'সংরক্ষণ', 'Save')),
              onPressed: () {
                final bn = LocaleService.isBangla;
                HistoryService.record(
                  kind: HistoryKind.calculator,
                  title: bn ? 'ছাড় ক্যালকুলেটর' : 'Discount Calculator',
                  subtitle: bn ? 'দাম ${_priceCtrl.text} ৳, ছাড় ${_pctCtrl.text}%' : 'Price ${_priceCtrl.text} ৳, Discount ${_pctCtrl.text}%',
                  result: result!,
                  inputs: {
                    bn ? 'দাম' : 'Price': _priceCtrl.text,
                    bn ? 'ছাড় (%)' : 'Discount (%)': _pctCtrl.text,
                    bn ? 'বাঁচলো' : 'Saved': savedTxt ?? '',
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

// ── Tip / bill split ────────────────────────────────────────────────────────
class TipCalculator extends StatefulWidget {
  const TipCalculator({super.key});
  @override
  State<TipCalculator> createState() => _TipCalculatorState();
}

class _TipCalculatorState extends State<TipCalculator> {
  final _billCtrl = TextEditingController();
  double _tipPct = 10;
  int _people = 1;

  @override
  Widget build(BuildContext context) {
    final bill = double.tryParse(_billCtrl.text) ?? 0;
    final tip = bill * _tipPct / 100;
    final total = bill + tip;
    final perPerson = _people > 0 ? total / _people : total;
    final fmt = NumberFormat.currency(locale: 'en_BD', symbol: '৳', decimalDigits: 2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(controller: _billCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr(context, 'বিলের পরিমাণ (৳)', 'Bill amount (৳)')), onChanged: (_) => setState(() {})),
        const SizedBox(height: 12),
        Text(tr(context, 'বকশিশ: ${_tipPct.round()}%', 'Tip: ${_tipPct.round()}%'), style: const TextStyle(fontWeight: FontWeight.w600)),
        Slider(value: _tipPct, min: 0, max: 30, divisions: 30, activeColor: AppColors.calculator, onChanged: (v) => setState(() => _tipPct = v)),
        Row(
          children: [
            Text(tr(context, 'জনসংখ্যা:', 'People:'), style: const TextStyle(fontWeight: FontWeight.w600)),
            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() => _people = (_people - 1).clamp(1, 50))),
            Text('$_people', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _people = (_people + 1).clamp(1, 50))),
          ],
        ),
        ResultText(tr(context, 'মোট ${fmt.format(total)} · জনপ্রতি ${fmt.format(perPerson)}', 'Total ${fmt.format(total)} · Per person ${fmt.format(perPerson)}')),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.history, size: 16),
            label: Text(tr(context, 'সংরক্ষণ', 'Save')),
            onPressed: () {
              final bn = LocaleService.isBangla;
              HistoryService.record(
                kind: HistoryKind.calculator,
                title: bn ? 'বকশিশ ক্যালকুলেটর' : 'Tip Calculator',
                subtitle: bn ? 'বিল ${_billCtrl.text} ৳, বকশিশ ${_tipPct.round()}%, $_people জন' : 'Bill ${_billCtrl.text} ৳, Tip ${_tipPct.round()}%, $_people people',
                result: bn ? 'মোট ${fmt.format(total)} · জনপ্রতি ${fmt.format(perPerson)}' : 'Total ${fmt.format(total)} · Per person ${fmt.format(perPerson)}',
                inputs: {
                  bn ? 'বিল (৳)' : 'Bill (৳)': _billCtrl.text,
                  bn ? 'বকশিশ (%)' : 'Tip (%)': _tipPct.round().toString(),
                  bn ? 'জন' : 'People': _people.toString(),
                  bn ? 'মোট' : 'Total': fmt.format(total),
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Length converter ────────────────────────────────────────────────────────
class LengthConverter extends StatefulWidget {
  const LengthConverter({super.key});
  @override
  State<LengthConverter> createState() => _LengthConverterState();
}

class _LengthConverterState extends State<LengthConverter> {
  final _valCtrl = TextEditingController(text: '1');
  String _from = 'm';
  static const Map<String, double> _toMeters = {
    'm': 1,
    'km': 1000,
    'ft': 0.3048,
    'in': 0.0254,
    'mi': 1609.34,
    'yd': 0.9144,
  };
  static const Map<String, _UnitDef> _units = {
    'm': _UnitDef('মিটার', 'Meter'),
    'km': _UnitDef('কিলোমিটার', 'Kilometer'),
    'ft': _UnitDef('ফুট', 'Foot'),
    'in': _UnitDef('ইঞ্চি', 'Inch'),
    'mi': _UnitDef('মাইল', 'Mile'),
    'yd': _UnitDef('গজ', 'Yard'),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final val = double.tryParse(_valCtrl.text) ?? 0;
    final meters = val * (_toMeters[_from] ?? 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: TextField(controller: _valCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr(context, 'মান', 'Value')), onChanged: (_) => setState(() {}))),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _from,
              items: _units.entries.map((u) => DropdownMenuItem(value: u.key, child: Text(tr(context, u.value.bn, u.value.en)))).toList(),
              onChanged: (v) => setState(() => _from = v ?? _from),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: _toMeters.entries.where((e) => e.key != _from).map((e) {
            final converted = meters / e.value;
            final def = _units[e.key]!;
            return Text('${NumberFormat('#,##0.###').format(converted)} ${tr(context, def.bn, def.en)}', style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant));
          }).toList(),
        ),
      ],
    );
  }
}

// ── Weight converter ────────────────────────────────────────────────────────
class WeightConverter extends StatefulWidget {
  const WeightConverter({super.key});
  @override
  State<WeightConverter> createState() => _WeightConverterState();
}

class _WeightConverterState extends State<WeightConverter> {
  final _valCtrl = TextEditingController(text: '1');
  String _from = 'kg';
  static const Map<String, double> _toKg = {
    'kg': 1,
    'g': 0.001,
    'lb': 0.453592,
    'mon': 37.3242,
  };
  static const Map<String, _UnitDef> _units = {
    'kg': _UnitDef('কিলোগ্রাম', 'Kilogram'),
    'g': _UnitDef('গ্রাম', 'Gram'),
    'lb': _UnitDef('পাউন্ড', 'Pound'),
    'mon': _UnitDef('মণ', 'Mon'),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final val = double.tryParse(_valCtrl.text) ?? 0;
    final kg = val * (_toKg[_from] ?? 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: TextField(controller: _valCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr(context, 'মান', 'Value')), onChanged: (_) => setState(() {}))),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _from,
              items: _units.entries.map((u) => DropdownMenuItem(value: u.key, child: Text(tr(context, u.value.bn, u.value.en)))).toList(),
              onChanged: (v) => setState(() => _from = v ?? _from),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: _toKg.entries.where((e) => e.key != _from).map((e) {
            final converted = kg / e.value;
            final def = _units[e.key]!;
            return Text('${NumberFormat('#,##0.###').format(converted)} ${tr(context, def.bn, def.en)}', style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant));
          }).toList(),
        ),
      ],
    );
  }
}

class _UnitDef {
  final String bn;
  final String en;
  const _UnitDef(this.bn, this.en);
}

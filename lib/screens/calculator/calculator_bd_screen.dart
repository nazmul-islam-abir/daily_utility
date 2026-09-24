import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

final _fmt = NumberFormat.currency(locale: 'en_BD', symbol: '৳', decimalDigits: 2);

class CalculatorBdScreen extends StatelessWidget {
  const CalculatorBdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tabs = <_CalcTab>[
      _CalcTab(
        'জমি পরিমাপ',
        'Land',
        const LandConverter(),
        noteBn: 'কাঠা/বিঘার হিসাব অঞ্চলভেদে সামান্য ভিন্ন হতে পারে — এখানে প্রচলিত মান ব্যবহার করা হয়েছে (১ শতাংশ = ৪৩৫.৬ বর্গফুট, ১ কাঠা = ৭২০ বর্গফুট, ১ বিঘা = ২০ কাঠা)।',
        noteEn: 'Katha/bigha conversions vary slightly by region — common figures used here (1 shotangsho = 435.6 sqft, 1 katha = 720 sqft, 1 bigha = 20 katha).',
      ),
      _CalcTab('ফুট ↔ হাত', 'Feet/Haat', const FeetHaatConverter()),
      _CalcTab('টাকার %', 'Money %', const TakaPercentage()),
      _CalcTab(
        'বেতন হিসাব',
        'Salary',
        const SalaryCalculator(),
        noteBn: 'এটি একটি সাধারণ প্রচলিত অনুপাত (৬০/৩০/১০) — প্রতিষ্ঠানভেদে গঠন ভিন্ন হতে পারে।',
        noteEn: 'This is a common default split (60/30/10) — actual salary structures vary by company.',
      ),
      _CalcTab(
        'বিদ্যুৎ বিল',
        'Electricity',
        const ElectricityCalculator(),
        noteBn: 'এটি একটি আনুমানিক হিসাব (উদাহরণস্বরূপ স্ল্যাব হার ব্যবহার করা হয়েছে)। সঠিক হারের জন্য আপনার বিতরণ কোম্পানির (DPDC/DESCO/NESCO/PBS) সর্বশেষ রেট দেখুন।',
        noteEn: 'This is an approximate estimate (sample slab rates). Check your distribution company (DPDC/DESCO/NESCO/PBS) for the latest rates.',
      ),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr(context, 'বাংলাদেশ বিশেষ ক্যালকুলেটর', 'BD Special Calculator')),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final t in tabs) Tab(text: tr(context, t.bn, t.en))],
          ),
        ),
        body: TabBarView(
          children: [
            for (final t in tabs)
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    t.child,
                    if (t.noteBn != null || t.noteEn != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        tr(context, t.noteBn ?? '', t.noteEn ?? ''),
                        style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant, height: 1.3),
                      ),
                    ],
                  ],
                ),
              ),
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
  final String? noteBn;
  final String? noteEn;
  _CalcTab(this.bn, this.en, this.child, {this.noteBn, this.noteEn});
}

class LandConverter extends StatefulWidget {
  const LandConverter({super.key});
  @override
  State<LandConverter> createState() => _LandConverterState();
}

class _LandConverterState extends State<LandConverter> {
  final _valCtrl = TextEditingController(text: '1');
  String _unit = 'shotangsho';
  static const Map<String, double> _toSqft = {
    'shotangsho': 435.6,
    'katha': 720,
    'bigha': 14400,
    'acre': 43560,
    'sqft': 1,
  };
  static const Map<String, _UnitDef> _units = {
    'shotangsho': _UnitDef('শতাংশ (Decimal)', 'Shotangsho (Decimal)'),
    'katha': _UnitDef('কাঠা', 'Katha'),
    'bigha': _UnitDef('বিঘা', 'Bigha'),
    'acre': _UnitDef('একর', 'Acre'),
    'sqft': _UnitDef('বর্গফুট', 'Square feet'),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final val = double.tryParse(_valCtrl.text) ?? 0;
    final sqft = val * (_toSqft[_unit] ?? 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _valCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr(context, 'মান', 'Value')),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _unit,
              items: _units.entries.map((u) => DropdownMenuItem(value: u.key, child: Text(tr(context, u.value.bn, u.value.en)))).toList(),
              onChanged: (v) => setState(() => _unit = v ?? _unit),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: _toSqft.entries.where((e) => e.key != _unit).map((e) {
            final converted = sqft / e.value;
            final def = _units[e.key]!;
            return Text(
              '${NumberFormat('#,##0.###').format(converted)} ${tr(context, def.bn, def.en)}',
              style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class FeetHaatConverter extends StatefulWidget {
  const FeetHaatConverter({super.key});
  @override
  State<FeetHaatConverter> createState() => _FeetHaatConverterState();
}

class _FeetHaatConverterState extends State<FeetHaatConverter> {
  final _feetCtrl = TextEditingController();
  final _haatCtrl = TextEditingController();
  static const double _feetPerHaat = 1.5;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _feetCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr(context, 'ফুট', 'Feet')),
                onChanged: (v) {
                  final f = double.tryParse(v);
                  _haatCtrl.text = f == null ? '' : (f / _feetPerHaat).toStringAsFixed(2);
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _haatCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr(context, 'হাত', 'Haat')),
                onChanged: (v) {
                  final h = double.tryParse(v);
                  _feetCtrl.text = h == null ? '' : (h * _feetPerHaat).toStringAsFixed(2);
                  setState(() {});
                },
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            tr(context, '১ হাত ≈ ১.৫ ফুট', '1 haat ≈ 1.5 feet'),
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class TakaPercentage extends StatefulWidget {
  const TakaPercentage({super.key});
  @override
  State<TakaPercentage> createState() => _TakaPercentageState();
}

class _TakaPercentageState extends State<TakaPercentage> {
  final _amountCtrl = TextEditingController();
  final _pctCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountCtrl.text);
    final pct = double.tryParse(_pctCtrl.text);
    final result = (amount != null && pct != null) ? amount * pct / 100 : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr(context, 'পরিমাণ (৳)', 'Amount (৳)')),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _pctCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr(context, 'শতাংশ (%)', 'Percent (%)')),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        if (result != null) ResultText('= ${_fmt.format(result)}'),
      ],
    );
  }
}

class SalaryCalculator extends StatefulWidget {
  const SalaryCalculator({super.key});
  @override
  State<SalaryCalculator> createState() => _SalaryCalculatorState();
}

class _SalaryCalculatorState extends State<SalaryCalculator> {
  final _grossCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gross = double.tryParse(_grossCtrl.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _grossCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: tr(context, 'মোট (গ্রস) বেতন (৳)', 'Gross salary (৳)')),
          onChanged: (_) => setState(() {}),
        ),
        if (gross != null) ...[
          const SizedBox(height: 10),
          _row(context, scheme, tr(context, 'বেসিক (৬০%)', 'Basic (60%)'), gross * 0.60),
          _row(context, scheme, tr(context, 'বাড়ি ভাড়া (৩০%)', 'House rent (30%)'), gross * 0.30),
          _row(context, scheme, tr(context, 'চিকিৎসা ভাতা (১০%)', 'Medical allowance (10%)'), gross * 0.10),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, ColorScheme scheme, String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(_fmt.format(value), style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.calculator)),
        ],
      ),
    );
  }
}

class ElectricityCalculator extends StatefulWidget {
  const ElectricityCalculator({super.key});
  @override
  State<ElectricityCalculator> createState() => _ElectricityCalculatorState();
}

class _ElectricityCalculatorState extends State<ElectricityCalculator> {
  final _unitsCtrl = TextEditingController();

  static const List<List<double>> _slabs = [
    [50, 4.63],
    [50, 5.26],
    [100, 7.20],
    [100, 7.59],
    [100, 8.02],
    [200, 12.67],
    [double.infinity, 14.61],
  ];

  @override
  Widget build(BuildContext context) {
    final units = double.tryParse(_unitsCtrl.text);
    double? bill;
    if (units != null && units >= 0) {
      double remaining = units;
      double total = 0;
      for (final slab in _slabs) {
        if (remaining <= 0) break;
        final slabSize = slab[0];
        final rate = slab[1];
        final used = remaining < slabSize ? remaining : slabSize;
        total += used * rate;
        remaining -= used;
      }
      bill = total;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _unitsCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: tr(context, 'ব্যবহৃত ইউনিট (kWh)', 'Units used (kWh)')),
          onChanged: (_) => setState(() {}),
        ),
        if (bill != null) ResultText(tr(context, 'আনুমানিক বিল ≈ ${_fmt.format(bill)} (ডিমান্ড চার্জ ও VAT ছাড়া)', 'Approx. bill ≈ ${_fmt.format(bill)} (excluding demand charge & VAT)')),
      ],
    );
  }
}

class _UnitDef {
  final String bn;
  final String en;
  const _UnitDef(this.bn, this.en);
}

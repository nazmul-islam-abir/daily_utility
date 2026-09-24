import 'package:flutter/material.dart';

import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// Every calculator here is a general informational tool only — never a
/// diagnosis or medical advice. Each card says so explicitly.
class CalculatorHealthScreen extends StatelessWidget {
  const CalculatorHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tabs = <_CalcTab>[
      _CalcTab('BMI', 'BMI', const BmiCalculator()),
      _CalcTab('BMR', 'BMR', const BmrCalculator()),
      _CalcTab('আদর্শ ওজন', 'Ideal Weight', const IdealWeightCalculator()),
      _CalcTab('পানি চাহিদা', 'Water Intake', const WaterIntakeCalculator()),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr(context, 'স্বাস্থ্য ক্যালকুলেটর', 'Health Calculator')),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final t in tabs) Tab(text: tr(context, t.bn, t.en))],
          ),
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr(context, 'এই ক্যালকুলেটরগুলো শুধুমাত্র সাধারণ ধারণা দেওয়ার জন্য — এগুলো মেডিকেল পরামর্শ বা রোগ নির্ণয় নয়। সিদ্ধান্তের আগে একজন ডাক্তারের পরামর্শ নিন।', 'These calculators provide general estimates only — they are not medical advice or diagnosis. Please consult a doctor before making any decisions.'),
                      style: TextStyle(fontSize: 12.5, color: scheme.onSurface, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final t in tabs)
                    SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), child: t.child),
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
  _CalcTab(this.bn, this.en, this.child);
}

class BmiCalculator extends StatefulWidget {
  const BmiCalculator({super.key});
  @override
  State<BmiCalculator> createState() => _BmiCalculatorState();
}

class _BmiCalculatorState extends State<BmiCalculator> {
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final heightCm = double.tryParse(_heightCtrl.text);
    final weight = double.tryParse(_weightCtrl.text);
    double? bmi;
    String category = '';
    if (heightCm != null && weight != null && heightCm > 0) {
      final h = heightCm / 100;
      bmi = weight / (h * h);
      if (bmi < 18.5) {
        category = tr(context, 'কম ওজন', 'Underweight');
      } else if (bmi < 25) {
        category = tr(context, 'স্বাভাবিক', 'Normal');
      } else if (bmi < 30) {
        category = tr(context, 'অতিরিক্ত ওজন', 'Overweight');
      } else {
        category = tr(context, 'স্থূলতা', 'Obese');
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _heightCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr(context, 'উচ্চতা (সেমি)', 'Height (cm)')),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _weightCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr(context, 'ওজন (কেজি)', 'Weight (kg)')),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        if (bmi != null) ResultText(tr(context, 'BMI = ${bmi.toStringAsFixed(1)} ($category)', 'BMI = ${bmi.toStringAsFixed(1)} ($category)')),
      ],
    );
  }
}

class BmrCalculator extends StatefulWidget {
  const BmrCalculator({super.key});
  @override
  State<BmrCalculator> createState() => _BmrCalculatorState();
}

class _BmrCalculatorState extends State<BmrCalculator> {
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _sex = 'male';

  @override
  Widget build(BuildContext context) {
    final h = double.tryParse(_heightCtrl.text);
    final w = double.tryParse(_weightCtrl.text);
    final a = double.tryParse(_ageCtrl.text);
    double? bmr;
    if (h != null && w != null && a != null) {
      bmr = (10 * w) + (6.25 * h) - (5 * a) + (_sex == 'male' ? 5 : -161);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(tr(context, 'পুরুষ', 'Male')),
              selected: _sex == 'male',
              onSelected: (_) => setState(() => _sex = 'male'),
            ),
            ChoiceChip(
              label: Text(tr(context, 'মহিলা', 'Female')),
              selected: _sex == 'female',
              onSelected: (_) => setState(() => _sex = 'female'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr(context, 'বয়স', 'Age')),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _heightCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr(context, 'উচ্চতা (সেমি)', 'Height (cm)')),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _weightCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr(context, 'ওজন (কেজি)', 'Weight (kg)')),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        if (bmr != null) ResultText(tr(context, 'BMR ≈ ${bmr.round()} kcal/দিন (বিশ্রামে)', 'BMR ≈ ${bmr.round()} kcal/day (at rest)')),
      ],
    );
  }
}

class IdealWeightCalculator extends StatefulWidget {
  const IdealWeightCalculator({super.key});
  @override
  State<IdealWeightCalculator> createState() => _IdealWeightCalculatorState();
}

class _IdealWeightCalculatorState extends State<IdealWeightCalculator> {
  final _heightCtrl = TextEditingController();
  String _sex = 'male';

  @override
  Widget build(BuildContext context) {
    final h = double.tryParse(_heightCtrl.text);
    double? ideal;
    if (h != null && h > 0) {
      final inches = h / 2.54;
      final over60 = (inches - 60).clamp(0, 1000);
      ideal = (_sex == 'male' ? 50 : 45.5) + 2.3 * over60;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(tr(context, 'পুরুষ', 'Male')),
              selected: _sex == 'male',
              onSelected: (_) => setState(() => _sex = 'male'),
            ),
            ChoiceChip(
              label: Text(tr(context, 'মহিলা', 'Female')),
              selected: _sex == 'female',
              onSelected: (_) => setState(() => _sex = 'female'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _heightCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: tr(context, 'উচ্চতা (সেমি)', 'Height (cm)')),
          onChanged: (_) => setState(() {}),
        ),
        if (ideal != null) ResultText(tr(context, 'আনুমানিক আদর্শ ওজন ≈ ${ideal.toStringAsFixed(1)} কেজি', 'Approx. ideal weight ≈ ${ideal.toStringAsFixed(1)} kg')),
      ],
    );
  }
}

class WaterIntakeCalculator extends StatefulWidget {
  const WaterIntakeCalculator({super.key});
  @override
  State<WaterIntakeCalculator> createState() => _WaterIntakeCalculatorState();
}

class _WaterIntakeCalculatorState extends State<WaterIntakeCalculator> {
  final _weightCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final w = double.tryParse(_weightCtrl.text);
    final liters = w != null ? w * 0.033 : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _weightCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: tr(context, 'ওজন (কেজি)', 'Weight (kg)')),
          onChanged: (_) => setState(() {}),
        ),
        if (liters != null) ResultText(tr(context, 'আনুমানিক ${liters.toStringAsFixed(1)} লিটার / দিন', 'Approx. ${liters.toStringAsFixed(1)} litres / day')),
      ],
    );
  }
}

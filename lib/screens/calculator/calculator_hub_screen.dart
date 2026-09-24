import 'package:flutter/material.dart';

import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import 'calculator_general_screen.dart';
import 'calculator_education_screen.dart';
import 'calculator_health_screen.dart';
import 'calculator_finance_screen.dart';
import 'calculator_bd_screen.dart';

class CalculatorHubScreen extends StatelessWidget {
  const CalculatorHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      _Cat('সাধারণ', 'General', 'বেসিক, শতাংশ, ছাড়, বকশিশ, একক রূপান্তর', 'Basic, percent, discount, tip, units', Icons.calculate_outlined, const CalculatorGeneralScreen()),
      _Cat('শিক্ষা', 'Education', 'GPA, CGPA, মার্কস, উপস্থিতি', 'GPA, CGPA, marks, attendance', Icons.school_outlined, const CalculatorEducationScreen()),
      _Cat('স্বাস্থ্য', 'Health', 'BMI, BMR, আদর্শ ওজন, পানি', 'BMI, BMR, ideal weight, water', Icons.favorite_outline, const CalculatorHealthScreen()),
      _Cat('আর্থিক', 'Finance', 'EMI, লোন, সঞ্চয়, সুদ, VAT', 'EMI, loan, savings, interest, VAT', Icons.savings_outlined, const CalculatorFinanceScreen()),
      _Cat('বাংলাদেশ বিশেষ', 'BD Special', 'জমি, বেতন, বিদ্যুৎ বিল', 'Land, salary, electricity bill', Icons.flag_outlined, const CalculatorBdScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'ক্যালকুলেটর', 'Calculator'))),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final c = categories[i];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CircleAvatar(backgroundColor: AppColors.calculator.withValues(alpha: 0.14), child: Icon(c.icon, color: AppColors.calculator)),
              title: Text(tr(context, c.titleBn, c.titleEn), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(tr(context, c.subtitleBn, c.subtitleEn)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textDim),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => c.screen)),
            ),
          );
        },
      ),
    );
  }
}

class _Cat {
  final String titleBn, titleEn;
  final String subtitleBn, subtitleEn;
  final IconData icon;
  final Widget screen;
  _Cat(this.titleBn, this.titleEn, this.subtitleBn, this.subtitleEn, this.icon, this.screen);
}

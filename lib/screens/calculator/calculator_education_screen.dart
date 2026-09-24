import 'package:flutter/material.dart';

import '../../services/locale_service.dart';
import '../../widgets/common_widgets.dart';

class CalculatorEducationScreen extends StatelessWidget {
  const CalculatorEducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tabs = <_CalcTab>[
      _CalcTab('GPA / CGPA', 'GPA / CGPA', const GpaCalculator()),
      _CalcTab('মার্কস → %', 'Marks %', const MarksPercentage()),
      _CalcTab('উপস্থিতি', 'Attendance', const AttendanceCalculator()),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr(context, 'শিক্ষা ক্যালকুলেটর', 'Education Calculator')),
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

class _GpaRow {
  final courseCtrl = TextEditingController();
  final creditCtrl = TextEditingController(text: '3');
  double grade = 4.0;
}

final Map<String, GradeDef> kGradeDefs = {
  'A+': GradeDef(4.0, '৪.০০', '4.00'),
  'A': GradeDef(3.75, '৩.৭৫', '3.75'),
  'A-': GradeDef(3.5, '৩.৫০', '3.50'),
  'B+': GradeDef(3.25, '৩.২৫', '3.25'),
  'B': GradeDef(3.0, '৩.০০', '3.00'),
  'B-': GradeDef(2.75, '২.৭৫', '2.75'),
  'C+': GradeDef(2.5, '২.৫০', '2.50'),
  'C': GradeDef(2.25, '২.২৫', '2.25'),
  'D': GradeDef(2.0, '২.০০', '2.00'),
  'F': GradeDef(0.0, '০.০০', '0.00'),
};

class GradeDef {
  final double points;
  final String bnNum;
  final String enNum;
  const GradeDef(this.points, this.bnNum, this.enNum);
}

class GpaCalculator extends StatefulWidget {
  const GpaCalculator({super.key});
  @override
  State<GpaCalculator> createState() => _GpaCalculatorState();
}

class _GpaCalculatorState extends State<GpaCalculator> {
  final List<_GpaRow> _rows = [_GpaRow(), _GpaRow()];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    double totalCredits = 0, totalPoints = 0;
    for (final r in _rows) {
      final credit = double.tryParse(r.creditCtrl.text) ?? 0;
      totalCredits += credit;
      totalPoints += credit * r.grade;
    }
    final gpa = totalCredits == 0 ? 0.0 : totalPoints / totalCredits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _rows[i].creditCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: tr(context, 'ক্রেডিট', 'Credit'), isDense: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: DropdownButtonFormField<double>(
                    value: _rows[i].grade,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: tr(context, 'গ্রেড', 'Grade'), isDense: true),
                    items: kGradeDefs.entries.map((e) {
                      final num = tr(context, e.value.bnNum, e.value.enNum);
                      return DropdownMenuItem(value: e.value.points, child: Text('${e.key} ($num)', overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (v) => setState(() => _rows[i].grade = v ?? 4.0),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: scheme.outline),
                  onPressed: () => setState(() => _rows.length > 1 ? _rows.removeAt(i) : null),
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: () => setState(() => _rows.add(_GpaRow())),
          icon: const Icon(Icons.add, size: 18),
          label: Text(tr(context, 'কোর্স যোগ করুন', 'Add course')),
        ),
        ResultText(tr(context, 'GPA/CGPA = ${gpa.toStringAsFixed(2)}  (মোট ক্রেডিট: ${totalCredits.toStringAsFixed(0)})', 'GPA/CGPA = ${gpa.toStringAsFixed(2)}  (Total credits: ${totalCredits.toStringAsFixed(0)})')),
      ],
    );
  }
}

class MarksPercentage extends StatefulWidget {
  const MarksPercentage({super.key});
  @override
  State<MarksPercentage> createState() => _MarksPercentageState();
}

class _MarksPercentageState extends State<MarksPercentage> {
  final _obtainedCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final obtained = double.tryParse(_obtainedCtrl.text);
    final total = double.tryParse(_totalCtrl.text);
    final pct = (obtained != null && total != null && total > 0) ? (obtained / total) * 100 : null;
    String grade = '';
    if (pct != null) {
      if (pct >= 80) {
        grade = 'A+';
      } else if (pct >= 70) {
        grade = 'A';
      } else if (pct >= 60) {
        grade = 'A-';
      } else if (pct >= 50) {
        grade = 'B';
      } else if (pct >= 40) {
        grade = 'C';
      } else if (pct >= 33) {
        grade = 'D';
      } else {
        grade = 'F';
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _obtainedCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr(context, 'প্রাপ্ত নম্বর', 'Obtained marks')),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _totalCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr(context, 'মোট নম্বর', 'Total marks')),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        if (pct != null) ResultText(tr(context, '${pct.toStringAsFixed(2)}% · আনুমানিক গ্রেড: $grade', '${pct.toStringAsFixed(2)}% · Approx. grade: $grade')),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            tr(context, 'গ্রেড সীমা প্রতিষ্ঠানভেদে ভিন্ন হতে পারে — এটি একটি সাধারণ অনুমান।', 'Grade boundaries vary by institution — this is a general estimate.'),
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant, height: 1.3),
          ),
        ),
      ],
    );
  }
}

class AttendanceCalculator extends StatefulWidget {
  const AttendanceCalculator({super.key});
  @override
  State<AttendanceCalculator> createState() => _AttendanceCalculatorState();
}

class _AttendanceCalculatorState extends State<AttendanceCalculator> {
  final _attendedCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _requiredCtrl = TextEditingController(text: '75');

  @override
  Widget build(BuildContext context) {
    final attended = double.tryParse(_attendedCtrl.text);
    final total = double.tryParse(_totalCtrl.text);
    final required = double.tryParse(_requiredCtrl.text) ?? 75;
    String? result;
    if (attended != null && total != null && total > 0) {
      final pct = (attended / total) * 100;
      if (pct >= required) {
        final maxTotalAllowed = (attended / (required / 100));
        final canMiss = (maxTotalAllowed - total).floor();
        result = tr(context, '${pct.toStringAsFixed(1)}% উপস্থিতি — আপনি আরও ${canMiss < 0 ? 0 : canMiss} টি ক্লাস মিস করতে পারবেন', '${pct.toStringAsFixed(1)}% attendance — you may miss ${canMiss < 0 ? 0 : canMiss} more classes');
      } else {
        int needed = 0;
        double a = attended, t = total;
        while ((a / t) * 100 < required && needed < 10000) {
          a += 1;
          t += 1;
          needed += 1;
        }
        result = tr(context, '${pct.toStringAsFixed(1)}% উপস্থিতি — $required% পেতে আরও $needed টি ক্লাসে (টানা) উপস্থিত থাকতে হবে', '${pct.toStringAsFixed(1)}% attendance — attend $needed more classes in a row to reach $required%');
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _attendedCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr(context, 'উপস্থিত ক্লাস', 'Attended classes')),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _totalCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr(context, 'মোট ক্লাস', 'Total classes')),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _requiredCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: tr(context, 'প্রয়োজনীয় উপস্থিতি (%)', 'Required attendance (%)')),
          onChanged: (_) => setState(() {}),
        ),
        if (result != null) ResultText(result),
      ],
    );
  }
}

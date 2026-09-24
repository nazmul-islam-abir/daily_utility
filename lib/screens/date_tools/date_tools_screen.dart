import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';

class DateToolsScreen extends StatelessWidget {
  const DateToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tabs = <_CalcTab>[
      _CalcTab('বয়স', 'Age', const AgeCalculator()),
      _CalcTab('ব্যবধান', 'Days Between', const DaysBetween()),
      _CalcTab('কাউন্টডাউন', 'Countdown', const EventCountdown()),
      _CalcTab('ক্যালেন্ডার', 'Calendar', const MonthCalendar()),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr(context, 'তারিখ টুলস', 'Date Tools')),
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

class AgeCalculator extends StatefulWidget {
  const AgeCalculator({super.key});
  @override
  State<AgeCalculator> createState() => _AgeCalculatorState();
}

class _AgeCalculatorState extends State<AgeCalculator> {
  DateTime? _dob;

  Future<void> _pick() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  @override
  Widget build(BuildContext context) {
    String result = '';
    if (_dob != null) {
      final now = DateTime.now();
      int years = now.year - _dob!.year;
      int months = now.month - _dob!.month;
      int days = now.day - _dob!.day;
      if (days < 0) {
        months -= 1;
        days += DateTime(now.year, now.month, 0).day;
      }
      if (months < 0) {
        years -= 1;
        months += 12;
      }
      result = tr(context, '$years বছর $months মাস $days দিন', '$years years $months months $days days');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _pick,
          icon: const Icon(Icons.cake_outlined, size: 18),
          label: Text(_dob == null ? tr(context, 'জন্মতারিখ নির্বাচন করুন', 'Pick date of birth') : DateFormat('d MMMM y').format(_dob!)),
        ),
        if (result.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            result,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.dateTools),
          ),
        ],
      ],
    );
  }
}

class DaysBetween extends StatefulWidget {
  const DaysBetween({super.key});
  @override
  State<DaysBetween> createState() => _DaysBetweenState();
}

class _DaysBetweenState extends State<DaysBetween> {
  DateTime? _from;
  DateTime? _to;

  Future<void> _pick(bool isFrom) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 20),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final diff = (_from != null && _to != null) ? _to!.difference(_from!).inDays.abs() : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: () => _pick(true),
              child: Text(_from == null ? tr(context, 'শুরুর তারিখ', 'Start date') : DateFormat('d MMM y').format(_from!)),
            ),
            OutlinedButton(
              onPressed: () => _pick(false),
              child: Text(_to == null ? tr(context, 'শেষ তারিখ', 'End date') : DateFormat('d MMM y').format(_to!)),
            ),
          ],
        ),
        if (diff != null) ...[
          const SizedBox(height: 10),
          Text(
            tr(context, '$diff দিন', '$diff days'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.dateTools),
          ),
        ],
      ],
    );
  }
}

class EventCountdown extends StatefulWidget {
  const EventCountdown({super.key});
  @override
  State<EventCountdown> createState() => _EventCountdownState();
}

class _EventCountdownState extends State<EventCountdown> {
  final _nameCtrl = TextEditingController(text: 'পরীক্ষা');
  DateTime? _date;

  Future<void> _pick() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final days = _date != null
        ? _date!.difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(controller: _nameCtrl, decoration: InputDecoration(labelText: tr(context, 'ইভেন্টের নাম', 'Event name'))),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _pick,
          icon: const Icon(Icons.event_outlined, size: 18),
          label: Text(_date == null ? tr(context, 'তারিখ নির্বাচন করুন', 'Pick a date') : DateFormat('d MMMM y').format(_date!)),
        ),
        if (days != null) ...[
          const SizedBox(height: 10),
          Text(
            days > 0
                ? tr(context, '${_nameCtrl.text.isEmpty ? 'ইভেন্ট' : _nameCtrl.text} পর্যন্ত আর $days দিন বাকি', '${_nameCtrl.text.isEmpty ? 'Event' : _nameCtrl.text} in $days days')
                : (days == 0 ? tr(context, 'আজই!', 'Today!') : tr(context, '${-days} দিন আগে চলে গেছে', '${-days} days ago')),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.dateTools),
          ),
        ],
      ],
    );
  }
}

class MonthCalendar extends StatelessWidget {
  const MonthCalendar({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      child: CalendarDatePicker(
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        onDateChanged: (_) {},
      ),
    );
  }
}

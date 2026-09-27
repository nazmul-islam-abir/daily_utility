import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';

/// Date Tools — hub screen that lists the four calculators as cards.
/// Tapping a card pushes the dedicated calculator screen (each calculator
/// keeps its own state — picked dates, results, etc.).
class DateToolsScreen extends StatelessWidget {
  const DateToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = <_Tool>[
      _Tool(
        bn: 'বয়স',
        en: 'Age',
        subBn: 'জন্মতারিখ থেকে সঠিক বয়স',
        subEn: 'Exact age from date of birth',
        icon: Icons.cake_outlined,
        color: AppColors.dateTools,
        screen: const AgeCalculator(),
      ),
      _Tool(
        bn: 'ব্যবধান',
        en: 'Days Between',
        subBn: 'দুই তারিখের মধ্যে কত দিন',
        subEn: 'Number of days between two dates',
        icon: Icons.date_range_outlined,
        color: AppColors.primary,
        screen: const DaysBetween(),
      ),
      _Tool(
        bn: 'কাউন্টডাউন',
        en: 'Countdown',
        subBn: 'গুরুত্বপূর্ণ ইভেন্টের বাকি দিন',
        subEn: 'Days remaining for an important event',
        icon: Icons.event_outlined,
        color: AppColors.warning,
        screen: const EventCountdown(),
      ),
      _Tool(
        bn: 'ক্যালেন্ডার',
        en: 'Calendar',
        subBn: 'পুরো মাস দেখুন ও তারিখ ব্রাউজ করুন',
        subEn: 'Browse the full month and pick a date',
        icon: Icons.calendar_month_outlined,
        color: AppColors.success,
        screen: const MonthCalendar(),
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: Text(tr(context, 'তারিখ টুলস', 'Date Tools')),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: tools.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final t = tools[i];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: t.color.withValues(alpha: 0.14),
                child: Icon(t.icon, color: t.color),
              ),
              title: Text(
                tr(context, t.bn, t.en),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(tr(context, t.subBn, t.subEn)),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _ToolScreen(tool: t),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Tool {
  final String bn;
  final String en;
  final String subBn;
  final String subEn;
  final IconData icon;
  final Color color;
  final Widget screen;
  const _Tool({
    required this.bn,
    required this.en,
    required this.subBn,
    required this.subEn,
    required this.icon,
    required this.color,
    required this.screen,
  });
}

/// Generic wrapper that gives each calculator its own AppBar (with a
/// back button) so navigating away doesn't pop back to the hub without
/// context.
class _ToolScreen extends StatelessWidget {
  final _Tool tool;
  const _ToolScreen({required this.tool});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, tool.bn, tool.en)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: tool.screen,
      ),
    );
  }
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
    final scheme = Theme.of(context).colorScheme;
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.dateTools),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          tr(context, 'আপনার জন্মতারিখ নির্বাচন করলে বয়স বছর, মাস ও দিনে দেখানো হবে।',
              'Pick your date of birth to see your exact age in years, months, and days.'),
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
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
    final scheme = Theme.of(context).colorScheme;
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
        const SizedBox(height: 6),
        Text(
          tr(context, 'দুটি তারিখ নির্বাচন করলে তাদের মধ্যবর্তী দিনের সংখ্যা দেখানো হবে।',
              'Pick two dates to see the number of days between them.'),
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
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
    final scheme = Theme.of(context).colorScheme;
    final days = _date != null
        ? _date!.difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameCtrl,
          style: TextStyle(color: scheme.onSurface),
          decoration: InputDecoration(labelText: tr(context, 'ইভেন্টের নাম', 'Event name')),
        ),
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Force the selected-day text to a colour that contrasts strongly with
    // the (light) primary used for the selection circle in dark mode —
    // without this override Flutter can render white-on-white.
    final selectedFg = isDark ? Colors.black : Colors.white;
    final pickerTheme = Theme.of(context).copyWith(
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surface,
        headerBackgroundColor: scheme.surface,
        headerForegroundColor: scheme.onSurface,
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return null;
        }),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return selectedFg;
          if (states.contains(WidgetState.disabled)) return scheme.onSurfaceVariant.withValues(alpha: 0.4);
          return scheme.onSurface;
        }),
        todayBackgroundColor: WidgetStateProperty.all(Colors.transparent),
        todayForegroundColor: WidgetStateProperty.all(AppColors.dateTools),
        weekdayStyle: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700),
      ),
    );
    return Theme(
      data: pickerTheme,
      child: SizedBox(
        height: 340,
        child: CalendarDatePicker(
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          onDateChanged: (_) {},
        ),
      ),
    );
  }
}

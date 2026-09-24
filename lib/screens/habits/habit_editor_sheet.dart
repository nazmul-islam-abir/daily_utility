import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/habit.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';

const _uuid = Uuid();

IconData _iconFromCode(int cp) {
  // ignore: non_const_argument_for_const_parameter
  return IconData(cp, fontFamily: 'MaterialIcons', matchTextDirection: false);
}

const _kIconChoices = [
  Icons.spa_outlined, Icons.self_improvement, Icons.local_drink_outlined, Icons.directions_run, Icons.book_outlined,
  Icons.bedtime_outlined, Icons.fitness_center, Icons.brush_outlined, Icons.music_note_outlined, Icons.savings_outlined,
  Icons.restaurant_outlined, Icons.code, Icons.headphones, Icons.directions_bike, Icons.pool,
];

const _kColorChoices = [
  0xFF14B8A6, 0xFF6366F1, 0xFF3D5AFE, 0xFFF59E0B, 0xFFEC4899, 0xFF10B981, 0xFFEF4444, 0xFF8B5CF6,
];

/// Habit editor — modal bottom sheet used for both create and edit.
class HabitEditorSheet extends StatefulWidget {
  final Habit? existing;
  const HabitEditorSheet({super.key, this.existing});

  @override
  State<HabitEditorSheet> createState() => _HabitEditorSheetState();
}

class _HabitEditorSheetState extends State<HabitEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late IconData _icon;
  late int _colorValue;
  late String _recurrence;
  late Set<int> _days;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _subtitle = TextEditingController(text: e?.subtitle ?? '');
    _icon = e == null ? Icons.spa_outlined : _iconFromCode(e.iconCodePoint);
    _colorValue = e?.colorValue ?? _kColorChoices.first;
    _recurrence = e?.recurrence ?? 'daily';
    _days = Set.of(e?.daysOfWeek ?? const [1, 2, 3, 4, 5, 6, 7]);
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = _title.text.trim();
    if (t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context, 'একটি শিরোনাম লিখুন', 'Please enter a title'))));
      return;
    }
    if (widget.existing != null) {
      final e = widget.existing!;
      e.title = t;
      e.subtitle = _subtitle.text;
      e.iconCodePoint = _icon.codePoint;
      e.colorValue = _colorValue;
      e.recurrence = _recurrence;
      e.daysOfWeek = _recurrence == 'daily' ? const [1, 2, 3, 4, 5, 6, 7] : (_days.toList()..sort());
      await e.save();
    } else {
      final h = Habit(
        id: _uuid.v4(),
        title: t,
        subtitle: _subtitle.text,
        iconCodePoint: _icon.codePoint,
        colorValue: _colorValue,
        recurrence: _recurrence,
        daysOfWeek: _recurrence == 'daily' ? const [1, 2, 3, 4, 5, 6, 7] : (_days.toList()..sort()),
        createdAt: DateTime.now(),
      );
      await HiveService.habits.put(h.id, h);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.notifier,
      builder: (context, locale, _) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 14),
                Text(widget.existing == null ? tr(context, 'নতুন অভ্যাস', 'New habit') : tr(context, 'সম্পাদনা', 'Edit'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                TextField(controller: _title, autofocus: true, decoration: InputDecoration(labelText: tr(context, 'শিরোনাম', 'Title'))),
                const SizedBox(height: 10),
                TextField(controller: _subtitle, decoration: InputDecoration(labelText: tr(context, 'বিবরণ (ঐচ্ছিক)', 'Subtitle (optional)'))),
                const SizedBox(height: 16),
                Text(tr(context, 'আইকন', 'Icon'), style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kIconChoices.map((i) {
                    final sel = i.codePoint == _icon.codePoint;
                    return GestureDetector(
                      onTap: () => setState(() => _icon = i),
                      child: Container(
                        width: 40, height: 40, alignment: Alignment.center,
                        decoration: BoxDecoration(color: sel ? Color(_colorValue).withValues(alpha: 0.18) : AppColors.surfaceAlt, shape: BoxShape.circle),
                        child: Icon(i, color: sel ? Color(_colorValue) : AppColors.textMuted, size: 20),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(tr(context, 'রঙ', 'Color'), style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: _kColorChoices.map((c) {
                    return GestureDetector(
                      onTap: () => setState(() => _colorValue = c),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(tr(context, 'পুনরাবৃত্তি', 'Recurrence'), style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'daily', label: Text(tr(context, 'প্রতিদিন', 'Daily'))),
                    ButtonSegment(value: 'weekly', label: Text(tr(context, 'সাপ্তাহিক', 'Weekly'))),
                  ],
                  selected: {_recurrence},
                  onSelectionChanged: (s) => setState(() => _recurrence = s.first),
                ),
                if (_recurrence == 'weekly') ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (int dow = 1; dow <= 7; dow++)
                        FilterChip(
                          label: Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][dow - 1]),
                          selected: _days.contains(dow),
                          showCheckmark: false,
                          onSelected: (v) => setState(() => v ? _days.add(dow) : _days.remove(dow)),
                          selectedColor: Color(_colorValue).withValues(alpha: 0.2),
                          labelStyle: TextStyle(color: _days.contains(dow) ? Color(_colorValue) : AppColors.text, fontWeight: FontWeight.w800),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Color(_colorValue), minimumSize: const Size(0, 52)),
                    onPressed: _save,
                    child: Text(widget.existing == null ? tr(context, 'অভ্যাস যোগ করুন', 'Add habit') : tr(context, 'সংরক্ষণ', 'Save')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
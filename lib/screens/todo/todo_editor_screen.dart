import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../models/todo_item.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

const _uuid = Uuid();

class PriorityDef {
  final String bn;
  final String en;
  const PriorityDef(this.bn, this.en);
}

class RecurrenceDef {
  final String bn;
  final String en;
  const RecurrenceDef(this.bn, this.en);
}

const Map<String, PriorityDef> kPriorityLabels = {
  'low': PriorityDef('কম', 'Low'),
  'medium': PriorityDef('মাঝারি', 'Medium'),
  'high': PriorityDef('জরুরি', 'High'),
};
const Map<String, Color> kPriorityColors = {'low': AppColors.success, 'medium': AppColors.warning, 'high': AppColors.danger};
const Map<String, RecurrenceDef> kRecurrenceLabels = {
  'none': RecurrenceDef('একবার', 'Once'),
  'daily': RecurrenceDef('প্রতিদিন', 'Daily'),
  'weekly': RecurrenceDef('প্রতি সপ্তাহে', 'Weekly'),
  'monthly': RecurrenceDef('প্রতি মাসে', 'Monthly'),
};

String priorityLabel(BuildContext context, String key) {
  final def = kPriorityLabels[key];
  if (def == null) return '';
  return tr(context, def.bn, def.en);
}

String recurrenceLabel(BuildContext context, String key) {
  final def = kRecurrenceLabels[key];
  if (def == null) return '';
  return tr(context, def.bn, def.en);
}

class TodoEditorScreen extends StatefulWidget {
  final TodoItem? existing;
  const TodoEditorScreen({super.key, this.existing});

  @override
  State<TodoEditorScreen> createState() => _TodoEditorScreenState();
}

class _TodoEditorScreenState extends State<TodoEditorScreen> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _priority = 'medium';
  String _recurrence = 'none';
  DateTime? _dueAt;
  int? _reminderMinutes;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _notesCtrl.text = e.notes ?? '';
      _priority = e.priority;
      _recurrence = e.recurrence;
      _dueAt = e.dueAt;
      _reminderMinutes = e.reminderMinutesBefore;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt ?? now.add(const Duration(hours: 1))),
    );
    setState(() {
      _dueAt = DateTime(date.year, date.month, date.day, time?.hour ?? 9, time?.minute ?? 0);
    });
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context, 'একটি শিরোনাম লিখুন', 'Please enter a title'))));
      return;
    }

    final isNew = widget.existing == null;
    final item = widget.existing ??
        TodoItem(id: _uuid.v4(), title: title, createdAt: DateTime.now());

    item
      ..title = title
      ..notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim()
      ..priority = _priority
      ..recurrence = _recurrence
      ..dueAt = _dueAt
      ..reminderMinutesBefore = _reminderMinutes;

    final bn = LocaleService.isBangla;
    await NotificationService.cancel(item.notificationId);
    item.notificationId = null;
    if (_dueAt != null && _reminderMinutes != null) {
      final fireAt = _dueAt!.subtract(Duration(minutes: _reminderMinutes!));
      item.notificationId = await NotificationService.scheduleReminder(
        idKey: item.id,
        title: bn ? 'কাজ: ${item.title}' : 'Task: ${item.title}',
        body: DateFormat('d MMM, hh:mm a').format(_dueAt!),
        fireAt: fireAt,
      );
    }

    if (isNew) {
      await HiveService.todos.put(item.id, item);
    } else {
      await item.save();
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? tr(context, 'নতুন কাজ', 'New task') : tr(context, 'কাজ সম্পাদনা', 'Edit task'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            TextField(
              controller: _titleCtrl,
              autofocus: widget.existing == null,
              decoration: InputDecoration(labelText: tr(context, 'শিরোনাম *', 'Title *'), hintText: tr(context, 'যেমন: বাজার করা', 'e.g. Buy groceries')),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(labelText: tr(context, 'নোট (ঐচ্ছিক)', 'Notes (optional)')),
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            SectionHeader(tr(context, 'অগ্রাধিকার', 'Priority')),
            Wrap(
              spacing: 8,
              children: kPriorityLabels.entries
                  .map((e) => ChoiceChip(
                        label: Text(priorityLabel(context, e.key)),
                        selected: _priority == e.key,
                        onSelected: (_) => setState(() => _priority = e.key),
                        selectedColor: kPriorityColors[e.key]?.withValues(alpha: 0.18),
                      ))
                  .toList(),
            ),
            SectionHeader(tr(context, 'পুনরাবৃত্তি', 'Recurrence')),
            Wrap(
              spacing: 8,
              children: kRecurrenceLabels.entries
                  .map((e) => ChoiceChip(
                        label: Text(recurrenceLabel(context, e.key)),
                        selected: _recurrence == e.key,
                        onSelected: (_) => setState(() => _recurrence = e.key),
                      ))
                  .toList(),
            ),
            SectionHeader(tr(context, 'নির্ধারিত তারিখ ও সময়', 'Due date & time')),
            OutlinedButton.icon(
              onPressed: _pickDueDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(_dueAt == null ? tr(context, 'তারিখ নির্বাচন করুন', 'Pick a date') : DateFormat('d MMMM y, hh:mm a').format(_dueAt!)),
            ),
            if (_dueAt != null)
              TextButton(
                onPressed: () => setState(() {
                  _dueAt = null;
                  _reminderMinutes = null;
                }),
                child: Text(tr(context, 'তারিখ সরান', 'Remove date')),
              ),
            if (_dueAt != null) ...[
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

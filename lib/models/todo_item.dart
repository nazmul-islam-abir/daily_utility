import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';

import '../services/locale_service.dart';

/// A single to-do item. Stored in the `todos` Hive box.
///
/// [reminderMinutesBefore] is optional — null means "no reminder was set".
/// When set, it must be one of [kReminderOffsets] (5/10/20/30/45/60 min).
class TodoItem extends HiveObject {
  String id;
  String title;
  String? notes;
  String priority; // 'low' | 'medium' | 'high'
  DateTime? dueAt; // date + time combined, null = no due date
  int? reminderMinutesBefore; // null = optional reminder not set
  String recurrence; // 'none' | 'daily' | 'weekly' | 'monthly'
  bool isCompleted;
  DateTime? completedAt;
  DateTime createdAt;
  int? notificationId; // used to cancel/reschedule the local notification

  TodoItem({
    required this.id,
    required this.title,
    this.notes,
    this.priority = 'medium',
    this.dueAt,
    this.reminderMinutesBefore,
    this.recurrence = 'none',
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    this.notificationId,
  });
}

/// The only reminder lead times the app offers — matches the spec exactly:
/// 5, 10, 20, 30, 45 minutes, or 1 hour before. Reminders are always optional.
const List<int> kReminderOffsets = [5, 10, 20, 30, 45, 60];

String reminderOffsetLabel(BuildContext context, int minutes) {
  if (minutes == 60) return tr(context, '১ ঘণ্টা আগে', '1 hour before');
  return tr(context, '$minutes মিনিট আগে', '$minutes min before');
}

class TodoItemAdapter extends TypeAdapter<TodoItem> {
  @override
  final int typeId = 0;

  @override
  TodoItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TodoItem(
      id: fields[0] as String,
      title: fields[1] as String,
      notes: fields[2] as String?,
      priority: fields[3] as String? ?? 'medium',
      dueAt: fields[4] as DateTime?,
      reminderMinutesBefore: fields[5] as int?,
      recurrence: fields[6] as String? ?? 'none',
      isCompleted: fields[7] as bool? ?? false,
      completedAt: fields[8] as DateTime?,
      createdAt: fields[9] as DateTime,
      notificationId: fields[10] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, TodoItem obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.notes)
      ..writeByte(3)
      ..write(obj.priority)
      ..writeByte(4)
      ..write(obj.dueAt)
      ..writeByte(5)
      ..write(obj.reminderMinutesBefore)
      ..writeByte(6)
      ..write(obj.recurrence)
      ..writeByte(7)
      ..write(obj.isCompleted)
      ..writeByte(8)
      ..write(obj.completedAt)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.notificationId);
  }
}

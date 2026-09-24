import 'package:hive/hive.dart';

/// A habit the user wants to perform regularly (e.g. "Morning Meditation",
/// "Drink 2L Water"). Stored in the `habits` box.
class Habit extends HiveObject {
  String id;
  String title;
  String subtitle;
  int iconCodePoint; // IconData.codePoint
  int colorValue;
  String recurrence; // 'daily' | 'weekly'
  List<int> daysOfWeek; // 1=Mon ... 7=Sun — only used when recurrence='weekly'
  DateTime createdAt;

  Habit({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.iconCodePoint,
    required this.colorValue,
    this.recurrence = 'daily',
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
    required this.createdAt,
  });
}

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 12;

  @override
  Habit read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      id: fields[0] as String,
      title: fields[1] as String,
      subtitle: (fields[2] as String?) ?? '',
      iconCodePoint: fields[3] as int,
      colorValue: fields[4] as int,
      recurrence: (fields[5] as String?) ?? 'daily',
      daysOfWeek: ((fields[6] as List?) ?? const [1, 2, 3, 4, 5, 6, 7]).cast<int>(),
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.title)
      ..writeByte(2)..write(obj.subtitle)
      ..writeByte(3)..write(obj.iconCodePoint)
      ..writeByte(4)..write(obj.colorValue)
      ..writeByte(5)..write(obj.recurrence)
      ..writeByte(6)..write(obj.daysOfWeek)
      ..writeByte(7)..write(obj.createdAt);
  }
}

/// One day's check for a habit. Stored in the `habit_checks` box keyed by
/// `${habitId}_${yyyy-mm-dd}` → bool (true = done that day).
class HabitCheck {
  final String habitId;
  final DateTime date;
  final bool done;

  HabitCheck({required this.habitId, required this.date, required this.done});

  static String key(String habitId, DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return '${habitId}_${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

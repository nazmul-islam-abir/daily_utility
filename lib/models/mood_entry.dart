import 'package:hive/hive.dart';

/// A daily mood entry. Stored in the `moods` box.
class MoodEntry extends HiveObject {
  String id;
  DateTime date;
  int moodLevel; // 1..5 (Awful..Amazing)
  String prompt;
  String body;
  DateTime createdAt;

  MoodEntry({
    required this.id,
    required this.date,
    required this.moodLevel,
    this.prompt = '',
    this.body = '',
    required this.createdAt,
  });
}

class MoodEntryAdapter extends TypeAdapter<MoodEntry> {
  @override
  final int typeId = 14;

  @override
  MoodEntry read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return MoodEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      moodLevel: fields[2] as int,
      prompt: (fields[3] as String?) ?? '',
      body: (fields[4] as String?) ?? '',
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MoodEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.date)
      ..writeByte(2)..write(obj.moodLevel)
      ..writeByte(3)..write(obj.prompt)
      ..writeByte(4)..write(obj.body)
      ..writeByte(5)..write(obj.createdAt);
  }
}

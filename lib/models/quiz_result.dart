import 'package:hive/hive.dart';

/// One finished quiz attempt. Stored in the `quiz_results` box.
class QuizResult extends HiveObject {
  String id;
  int score; // 0..100
  int correctCount;
  int totalQuestions;
  DateTime completedAt;

  QuizResult({
    required this.id,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.completedAt,
  });
}

class QuizResultAdapter extends TypeAdapter<QuizResult> {
  @override
  final int typeId = 16;

  @override
  QuizResult read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return QuizResult(
      id: fields[0] as String,
      score: fields[1] as int,
      correctCount: fields[2] as int,
      totalQuestions: fields[3] as int,
      completedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, QuizResult obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.score)
      ..writeByte(2)..write(obj.correctCount)
      ..writeByte(3)..write(obj.totalQuestions)
      ..writeByte(4)..write(obj.completedAt);
  }
}

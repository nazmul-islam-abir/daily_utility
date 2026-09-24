import 'package:hive/hive.dart';

enum HistoryKind { calculator, finance, note, habit, mood, vault }

class HistoryEntry extends HiveObject {
  String id;
  String kind;
  String title;
  String subtitle;
  String result;
  Map<String, String> inputs;
  DateTime createdAt;

  HistoryEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.result,
    required this.inputs,
    required this.createdAt,
  });

  HistoryKind get kindEnum {
    switch (kind) {
      case 'calculator':
        return HistoryKind.calculator;
      case 'finance':
        return HistoryKind.finance;
      case 'habit':
        return HistoryKind.habit;
      case 'mood':
        return HistoryKind.mood;
      case 'vault':
        return HistoryKind.vault;
      default:
        return HistoryKind.note;
    }
  }
}

class HistoryEntryAdapter extends TypeAdapter<HistoryEntry> {
  @override
  final int typeId = 11;

  @override
  HistoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryEntry(
      id: fields[0] as String,
      kind: fields[1] as String,
      title: fields[2] as String,
      subtitle: fields[3] as String? ?? '',
      result: fields[4] as String,
      inputs: ((fields[5] as Map?) ?? {}).map((k, v) => MapEntry(k.toString(), v.toString())),
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.kind)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.subtitle)
      ..writeByte(4)
      ..write(obj.result)
      ..writeByte(5)
      ..write(obj.inputs)
      ..writeByte(6)
      ..write(obj.createdAt);
  }
}

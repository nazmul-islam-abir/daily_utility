import 'package:hive/hive.dart';

/// One line of a checklist-type note.
class ChecklistItem {
  String id;
  String text;
  bool checked;

  ChecklistItem({required this.id, required this.text, this.checked = false});
}

class ChecklistItemAdapter extends TypeAdapter<ChecklistItem> {
  @override
  final int typeId = 2;

  @override
  ChecklistItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChecklistItem(
      id: fields[0] as String,
      text: fields[1] as String,
      checked: fields[2] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, ChecklistItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.checked);
  }
}

/// A note. [type] is 'text' or 'checklist'.
///
/// Voice notes are modelled ([type] == 'voice') but not implemented in this
/// pass — recording audio needs a microphone plugin and platform permission
/// wiring that's out of scope here; the UI shows an honest "not available
/// yet" state rather than faking it.
class Note extends HiveObject {
  String id;
  String title;
  String body; // used when type == 'text'
  String type; // 'text' | 'checklist' | 'voice'
  List<ChecklistItem> checklistItems;
  bool isPinned;
  bool isSticky; // shown on the home dashboard sticky-notes strip
  int colorValue; // ARGB int for the note's accent colour
  DateTime createdAt;
  DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    this.body = '',
    this.type = 'text',
    List<ChecklistItem>? checklistItems,
    this.isPinned = false,
    this.isSticky = false,
    this.colorValue = 0xFFF2A93B,
    required this.createdAt,
    required this.updatedAt,
  }) : checklistItems = checklistItems ?? [];
}

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 1;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      id: fields[0] as String,
      title: fields[1] as String,
      body: fields[2] as String? ?? '',
      type: fields[3] as String? ?? 'text',
      checklistItems: (fields[4] as List?)?.cast<ChecklistItem>() ?? [],
      isPinned: fields[5] as bool? ?? false,
      isSticky: fields[9] as bool? ?? false,
      colorValue: fields[6] as int? ?? 0xFFF2A93B,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.checklistItems)
      ..writeByte(5)
      ..write(obj.isPinned)
      ..writeByte(6)
      ..write(obj.colorValue)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.isSticky);
  }
}

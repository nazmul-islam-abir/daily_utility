import 'package:hive/hive.dart';

/// A person you lend to / borrow from. Stored in the `baki_people` box.
/// The running balance is derived from that person's [LedgerEntry] list,
/// never stored directly, so it can never drift out of sync.
class Person extends HiveObject {
  String id;
  String name;
  String? phone;
  DateTime createdAt;

  Person({required this.id, required this.name, this.phone, required this.createdAt});
}

class PersonAdapter extends TypeAdapter<Person> {
  @override
  final int typeId = 4;

  @override
  Person read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Person(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String?,
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Person obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.createdAt);
  }
}

/// One movement of money with a person.
/// `direction == 'gave'` → you gave them money → they owe you more.
/// `direction == 'got'`  → you received money from them → they owe you less
/// (and can go negative, meaning you now owe them).
class LedgerEntry extends HiveObject {
  String id;
  String personId;
  double amount; // always entered as a positive number
  String direction; // 'gave' | 'got'
  String? note;
  DateTime date;

  LedgerEntry({
    required this.id,
    required this.personId,
    required this.amount,
    required this.direction,
    this.note,
    required this.date,
  });

  /// Signed contribution to the person's balance: positive = they owe you.
  double get signedAmount => direction == 'gave' ? amount : -amount;
}

class LedgerEntryAdapter extends TypeAdapter<LedgerEntry> {
  @override
  final int typeId = 5;

  @override
  LedgerEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LedgerEntry(
      id: fields[0] as String,
      personId: fields[1] as String,
      amount: (fields[2] as num).toDouble(),
      direction: fields[3] as String,
      note: fields[4] as String?,
      date: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LedgerEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.personId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.direction)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.date);
  }
}

import 'package:hive/hive.dart';

const List<String> kExpenseCategories = [
  'Food', 'Transport', 'Shopping', 'Education', 'Medical', 'Bills', 'Other',
];
const List<String> kIncomeCategories = [
  'Salary', 'Business', 'Gift', 'Other',
];

/// One income or expense entry. Stored in the `transactions` box.
class MoneyTransaction extends HiveObject {
  String id;
  String type; // 'income' | 'expense'
  double amount;
  String category;
  String? note;
  DateTime date;
  DateTime createdAt;

  MoneyTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    this.note,
    required this.date,
    required this.createdAt,
  });
}

class MoneyTransactionAdapter extends TypeAdapter<MoneyTransaction> {
  @override
  final int typeId = 3;

  @override
  MoneyTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoneyTransaction(
      id: fields[0] as String,
      type: fields[1] as String,
      amount: (fields[2] as num).toDouble(),
      category: fields[3] as String,
      note: fields[4] as String?,
      date: fields[5] as DateTime,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MoneyTransaction obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.createdAt);
  }
}

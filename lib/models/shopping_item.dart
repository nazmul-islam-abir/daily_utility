import 'package:hive/hive.dart';

/// One line in the shared shopping list. Stored in the `shopping` box.
class ShoppingItem extends HiveObject {
  String id;
  String name;
  String? quantity;
  bool checked;
  DateTime createdAt;

  ShoppingItem({
    required this.id,
    required this.name,
    this.quantity,
    this.checked = false,
    required this.createdAt,
  });
}

class ShoppingItemAdapter extends TypeAdapter<ShoppingItem> {
  @override
  final int typeId = 8;

  @override
  ShoppingItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShoppingItem(
      id: fields[0] as String,
      name: fields[1] as String,
      quantity: fields[2] as String?,
      checked: fields[3] as bool? ?? false,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ShoppingItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.checked)
      ..writeByte(4)
      ..write(obj.createdAt);
  }
}

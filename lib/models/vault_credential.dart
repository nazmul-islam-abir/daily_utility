import 'package:hive/hive.dart';

/// A stored password / login credential. Stored in the `vault` box.
class VaultCredential extends HiveObject {
  String id;
  String title;
  String username;
  String password;
  String? url;
  String category; // 'banking' | 'social' | 'work' | 'other'
  int iconCodePoint;
  int colorValue;
  DateTime createdAt;

  VaultCredential({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    this.url,
    this.category = 'other',
    required this.iconCodePoint,
    required this.colorValue,
    required this.createdAt,
  });

  bool get isWeak => password.length < 8;

  bool get isCompromised {
    final p = password.toLowerCase();
    return p.contains('password') || p.contains('123456') || p == '12345678' || p == 'qwerty' || p == 'abc123';
  }
}

class VaultCredentialAdapter extends TypeAdapter<VaultCredential> {
  @override
  final int typeId = 15;

  @override
  VaultCredential read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return VaultCredential(
      id: fields[0] as String,
      title: fields[1] as String,
      username: fields[2] as String,
      password: fields[3] as String,
      url: fields[4] as String?,
      category: (fields[5] as String?) ?? 'other',
      iconCodePoint: fields[6] as int,
      colorValue: fields[7] as int,
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, VaultCredential obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.title)
      ..writeByte(2)..write(obj.username)
      ..writeByte(3)..write(obj.password)
      ..writeByte(4)..write(obj.url)
      ..writeByte(5)..write(obj.category)
      ..writeByte(6)..write(obj.iconCodePoint)
      ..writeByte(7)..write(obj.colorValue)
      ..writeByte(8)..write(obj.createdAt);
  }
}

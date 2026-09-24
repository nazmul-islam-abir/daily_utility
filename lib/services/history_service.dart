import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/history_entry.dart';

const _uuid = Uuid();

class HistoryService {
  HistoryService._();

  static Box<HistoryEntry> get box => Hive.box<HistoryEntry>('history');

  static Future<void> record({
    required HistoryKind kind,
    required String title,
    required String subtitle,
    required String result,
    required Map<String, String> inputs,
  }) async {
    final entry = HistoryEntry(
      id: _uuid.v4(),
      kind: kind.name,
      title: title,
      subtitle: subtitle,
      result: result,
      inputs: inputs,
      createdAt: DateTime.now(),
    );
    await box.put(entry.id, entry);
  }

  static Future<void> clearAll() async {
    await box.clear();
  }

  static Future<void> clearKind(HistoryKind kind) async {
    final keys = box.values.where((e) => e.kind == kind.name).map((e) => e.id).toList();
    await box.deleteAll(keys);
  }

  static List<HistoryEntry> all() {
    final list = box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static List<HistoryEntry> ofKind(HistoryKind kind) {
    return all().where((e) => e.kind == kind.name).toList();
  }
}

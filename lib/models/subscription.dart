import 'package:hive/hive.dart';

/// How often a subscription renews / is billed.
enum BillingCycle {
  weekly,
  monthly,
  quarterly,
  yearly;

  String get key {
    switch (this) {
      case BillingCycle.weekly:
        return 'weekly';
      case BillingCycle.monthly:
        return 'monthly';
      case BillingCycle.quarterly:
        return 'quarterly';
      case BillingCycle.yearly:
        return 'yearly';
    }
  }

  static BillingCycle fromKey(String? key) {
    switch (key) {
      case 'weekly':
        return BillingCycle.weekly;
      case 'quarterly':
        return BillingCycle.quarterly;
      case 'yearly':
        return BillingCycle.yearly;
      case 'monthly':
      default:
        return BillingCycle.monthly;
    }
  }
}

/// Adapter for [BillingCycle] enum. Storing as a single byte ordinal keeps the
/// box file compact and avoids any locale-dependent string differences.
class BillingCycleAdapter extends TypeAdapter<BillingCycle> {
  @override
  final int typeId = 18;

  @override
  BillingCycle read(BinaryReader reader) {
    final i = reader.readByte();
    return BillingCycle.values[i.clamp(0, BillingCycle.values.length - 1)];
  }

  @override
  void write(BinaryWriter writer, BillingCycle obj) {
    writer.writeByte(obj.index);
  }
}

/// One recurring subscription — Netflix, gym, internet bill, insurance, etc.
/// Stored in the `subscriptions` box.
class Subscription extends HiveObject {
  String id;
  String title;
  double amount;
  BillingCycle cycle;
  DateTime nextRenewalDate;
  String category;
  String? notes;
  int? reminderDaysBefore;
  int? notificationId;
  String currency;
  bool isActive;
  int colorValue;
  DateTime createdAt;

  Subscription({
    required this.id,
    required this.title,
    required this.amount,
    required this.cycle,
    required this.nextRenewalDate,
    this.category = 'general',
    this.notes,
    this.reminderDaysBefore,
    this.notificationId,
    this.currency = 'BDT',
    this.isActive = true,
    this.colorValue = 0xFFEC4899,
    required this.createdAt,
  });

  /// Days remaining until [nextRenewalDate]. Negative means overdue.
  int daysUntilRenewal({DateTime? now}) {
    final today = DateTime(now?.year ?? DateTime.now().year, now?.month ?? DateTime.now().month, now?.day ?? DateTime.now().day);
    final due = DateTime(nextRenewalDate.year, nextRenewalDate.month, nextRenewalDate.day);
    return due.difference(today).inDays;
  }

  /// Returns the next [count] upcoming renewal dates (including the current
  /// [nextRenewalDate]). Useful for showing a multi-month preview.
  List<DateTime> upcomingRenewals({int count = 6}) {
    final list = <DateTime>[nextRenewalDate];
    var cursor = nextRenewalDate;
    for (var i = 1; i < count; i++) {
      cursor = advance(cursor, cycle);
      list.add(cursor);
    }
    return list;
  }

  /// Normalise [amount] into a monthly equivalent so multiple cycles can be
  /// added together cleanly on the home dashboard.
  double get monthlyEquivalent {
    switch (cycle) {
      case BillingCycle.weekly:
        return amount * 52 / 12;
      case BillingCycle.monthly:
        return amount;
      case BillingCycle.quarterly:
        return amount / 3;
      case BillingCycle.yearly:
        return amount / 12;
    }
  }

  /// Normalise [amount] into a yearly equivalent.
  double get yearlyEquivalent {
    switch (cycle) {
      case BillingCycle.weekly:
        return amount * 52;
      case BillingCycle.monthly:
        return amount * 12;
      case BillingCycle.quarterly:
        return amount * 4;
      case BillingCycle.yearly:
        return amount;
    }
  }

  /// Advance [d] by one [cycle]. Clamps the day to the last day of the
  /// target month so e.g. 31-Jan → 28-Feb doesn't skip a month.
  static DateTime advance(DateTime d, BillingCycle c) {
    switch (c) {
      case BillingCycle.weekly:
        return DateTime(d.year, d.month, d.day + 7);
      case BillingCycle.monthly:
        return _addMonths(d, 1);
      case BillingCycle.quarterly:
        return _addMonths(d, 3);
      case BillingCycle.yearly:
        return _addMonths(d, 12);
    }
  }

  static DateTime _addMonths(DateTime d, int months) {
    final totalMonth = d.month + months;
    final newYear = d.year + ((totalMonth - 1) ~/ 12);
    final newMonth = ((totalMonth - 1) % 12) + 1;
    final lastDayOfMonth = DateTime(newYear, newMonth + 1, 0).day;
    final newDay = d.day > lastDayOfMonth ? lastDayOfMonth : d.day;
    return DateTime(newYear, newMonth, newDay);
  }
}

class SubscriptionAdapter extends TypeAdapter<Subscription> {
  @override
  final int typeId = 17;

  @override
  Subscription read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Subscription(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: (fields[2] as num).toDouble(),
      cycle: BillingCycle.fromKey(fields[3] as String?),
      nextRenewalDate: fields[4] as DateTime,
      category: (fields[5] as String?) ?? 'general',
      notes: fields[6] as String?,
      reminderDaysBefore: fields[7] as int?,
      notificationId: fields[8] as int?,
      currency: (fields[9] as String?) ?? 'BDT',
      isActive: (fields[10] as bool?) ?? true,
      colorValue: (fields[11] as int?) ?? 0xFFEC4899,
      createdAt: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Subscription obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.cycle.key)
      ..writeByte(4)
      ..write(obj.nextRenewalDate)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.reminderDaysBefore)
      ..writeByte(8)
      ..write(obj.notificationId)
      ..writeByte(9)
      ..write(obj.currency)
      ..writeByte(10)
      ..write(obj.isActive)
      ..writeByte(11)
      ..write(obj.colorValue)
      ..writeByte(12)
      ..write(obj.createdAt);
  }
}
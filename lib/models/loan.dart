import 'package:hive/hive.dart';

/// One repayment made against a [Loan].
class LoanPayment {
  String id;
  double amount;
  DateTime date;
  String? note;

  LoanPayment({required this.id, required this.amount, required this.date, this.note});
}

class LoanPaymentAdapter extends TypeAdapter<LoanPayment> {
  @override
  final int typeId = 7;

  @override
  LoanPayment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LoanPayment(
      id: fields[0] as String,
      amount: (fields[1] as num).toDouble(),
      date: fields[2] as DateTime,
      note: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LoanPayment obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.note);
  }
}

/// A tracked loan — principal, interest, the monthly instalment, and every
/// payment made against it. Stored in the `loans` box.
class Loan extends HiveObject {
  String id;
  String title;
  double principal;
  double interestRatePercent; // annual, simple/flat rate used for the EMI estimate
  double monthlyPayment;
  DateTime startDate;
  int? termMonths;
  DateTime? nextPaymentDate;
  int? reminderMinutesBefore;
  int? notificationId;
  List<LoanPayment> payments;
  DateTime createdAt;

  Loan({
    required this.id,
    required this.title,
    required this.principal,
    required this.interestRatePercent,
    required this.monthlyPayment,
    required this.startDate,
    this.termMonths,
    this.nextPaymentDate,
    this.reminderMinutesBefore,
    this.notificationId,
    List<LoanPayment>? payments,
    required this.createdAt,
  }) : payments = payments ?? [];

  double get totalPaid => payments.fold(0.0, (sum, p) => sum + p.amount);
  double get remainingBalance => (principal - totalPaid).clamp(0, double.infinity);
}

class LoanAdapter extends TypeAdapter<Loan> {
  @override
  final int typeId = 6;

  @override
  Loan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Loan(
      id: fields[0] as String,
      title: fields[1] as String,
      principal: (fields[2] as num).toDouble(),
      interestRatePercent: (fields[3] as num).toDouble(),
      monthlyPayment: (fields[4] as num).toDouble(),
      startDate: fields[5] as DateTime,
      termMonths: fields[6] as int?,
      nextPaymentDate: fields[7] as DateTime?,
      reminderMinutesBefore: fields[8] as int?,
      notificationId: fields[9] as int?,
      payments: (fields[10] as List?)?.cast<LoanPayment>() ?? [],
      createdAt: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Loan obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.principal)
      ..writeByte(3)
      ..write(obj.interestRatePercent)
      ..writeByte(4)
      ..write(obj.monthlyPayment)
      ..writeByte(5)
      ..write(obj.startDate)
      ..writeByte(6)
      ..write(obj.termMonths)
      ..writeByte(7)
      ..write(obj.nextPaymentDate)
      ..writeByte(8)
      ..write(obj.reminderMinutesBefore)
      ..writeByte(9)
      ..write(obj.notificationId)
      ..writeByte(10)
      ..write(obj.payments)
      ..writeByte(11)
      ..write(obj.createdAt);
  }
}

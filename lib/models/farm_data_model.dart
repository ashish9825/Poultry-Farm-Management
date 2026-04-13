import 'package:uuid/uuid.dart';

class FarmData {
  final String id;
  final String date;
  final String breed;
  final int numberOfChicks;
  final double chicksAmount;
  final double medicineAmount;
  final double grainsAmount;
  final double otherExpenses;
  final String notes;
  final String createdAt;

  FarmData({
    String? id,
    required this.date,
    this.breed = '',
    required this.numberOfChicks,
    required this.chicksAmount,
    required this.medicineAmount,
    required this.grainsAmount,
    required this.otherExpenses,
    required this.notes,
    String? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  double get totalExpense => chicksAmount + medicineAmount + grainsAmount + otherExpenses;

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'breed': breed,
        'numberOfChicks': numberOfChicks,
        'chicksAmount': chicksAmount,
        'medicineAmount': medicineAmount,
        'grainsAmount': grainsAmount,
        'otherExpenses': otherExpenses,
        'notes': notes,
        'createdAt': createdAt,
      };

  factory FarmData.fromMap(Map<String, dynamic> map) => FarmData(
        id: map['id'],
        date: map['date'],
        breed: map['breed'] ?? '',
        numberOfChicks: (map['numberOfChicks'] as num?)?.toInt() ?? 0,
        chicksAmount: (map['chicksAmount'] as num?)?.toDouble() ?? 0,
        medicineAmount: (map['medicineAmount'] as num?)?.toDouble() ?? 0,
        grainsAmount: (map['grainsAmount'] as num?)?.toDouble() ?? 0,
        otherExpenses: (map['otherExpenses'] as num?)?.toDouble() ?? 0,
        notes: map['notes'] ?? '',
        createdAt: map['createdAt'],
      );
}

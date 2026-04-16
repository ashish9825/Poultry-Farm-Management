import 'package:uuid/uuid.dart';

class Medicine {
  final String id;
  final String date;
  final String name;
  final double cost;
  final String notes;
  final String paymentMode;
  final String createdAt;

  Medicine({
    String? id,
    required this.date,
    required this.name,
    required this.cost,
    this.notes = '',
    this.paymentMode = 'Cash',
    String? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'name': name,
        'cost': cost,
        'notes': notes,
        'paymentMode': paymentMode,
        'createdAt': createdAt,
      };

  factory Medicine.fromMap(Map<String, dynamic> map) => Medicine(
        id: map['id'],
        date: map['date'],
        name: map['name'] ?? '',
        cost: (map['cost'] as num?)?.toDouble() ?? 0,
        notes: map['notes'] ?? '',
        paymentMode: map['paymentMode'] ?? 'Cash',
        createdAt: map['createdAt'],
      );
}

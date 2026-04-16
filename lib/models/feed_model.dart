import 'package:uuid/uuid.dart';

class Feed {
  final String id;
  final String date;
  final String type; // grains, pellets, etc.
  final double quantity; // in kg or bags
  final double cost;
  final String notes;
  final String paymentMode;
  final String createdAt;

  Feed({
    String? id,
    required this.date,
    required this.type,
    required this.quantity,
    required this.cost,
    this.notes = '',
    this.paymentMode = 'Cash',
    String? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'type': type,
        'quantity': quantity,
        'cost': cost,
        'notes': notes,
        'paymentMode': paymentMode,
        'createdAt': createdAt,
      };

  factory Feed.fromMap(Map<String, dynamic> map) => Feed(
        id: map['id'],
        date: map['date'],
        type: map['type'] ?? '',
        quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
        cost: (map['cost'] as num?)?.toDouble() ?? 0,
        notes: map['notes'] ?? '',
        paymentMode: map['paymentMode'] ?? 'Cash',
        createdAt: map['createdAt'],
      );
}

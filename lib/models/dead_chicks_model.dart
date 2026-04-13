import 'package:uuid/uuid.dart';

class DeadChicks {
  final String id;
  final String date;
  final int count;
  final String notes;
  final String createdAt;

  DeadChicks({
    String? id,
    required this.date,
    required this.count,
    this.notes = '',
    String? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'count': count,
        'notes': notes,
        'createdAt': createdAt,
      };

  factory DeadChicks.fromMap(Map<String, dynamic> map) => DeadChicks(
        id: map['id'],
        date: map['date'],
        count: (map['count'] as num?)?.toInt() ?? 0,
        notes: map['notes'] ?? '',
        createdAt: map['createdAt'],
      );
}

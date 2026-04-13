import 'package:uuid/uuid.dart';

class Labour {
  final String id;
  final String name;
  final String mobileNo;
  final String address;
  final String joiningDate;
  final double dailyWage;
  final int totalDaysWorked;
  final double totalPaid;
  final double remainingPayment;
  final String role;
  final String createdAt;

  Labour({
    String? id,
    required this.name,
    required this.mobileNo,
    required this.address,
    required this.joiningDate,
    required this.dailyWage,
    required this.totalDaysWorked,
    required this.totalPaid,
    required this.role,
    String? createdAt,
  })  : id = id ?? const Uuid().v4(),
        remainingPayment = (dailyWage * totalDaysWorked) - totalPaid,
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  double get totalEarned => dailyWage * totalDaysWorked;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'mobileNo': mobileNo,
        'address': address,
        'joiningDate': joiningDate,
        'dailyWage': dailyWage,
        'totalDaysWorked': totalDaysWorked,
        'totalPaid': totalPaid,
        'remainingPayment': remainingPayment,
        'role': role,
        'createdAt': createdAt,
      };

  factory Labour.fromMap(Map<String, dynamic> map) => Labour(
        id: map['id'],
        name: map['name'],
        mobileNo: map['mobileNo'] ?? '',
        address: map['address'] ?? '',
        joiningDate: map['joiningDate'] ?? '',
        dailyWage: (map['dailyWage'] as num?)?.toDouble() ?? 0,
        totalDaysWorked: (map['totalDaysWorked'] as num?)?.toInt() ?? 0,
        totalPaid: (map['totalPaid'] as num?)?.toDouble() ?? 0,
        role: map['role'] ?? 'General Worker',
        createdAt: map['createdAt'],
      );

  Labour copyWith({
    String? name,
    String? mobileNo,
    String? address,
    String? joiningDate,
    double? dailyWage,
    int? totalDaysWorked,
    double? totalPaid,
    String? role,
  }) =>
      Labour(
        id: id,
        name: name ?? this.name,
        mobileNo: mobileNo ?? this.mobileNo,
        address: address ?? this.address,
        joiningDate: joiningDate ?? this.joiningDate,
        dailyWage: dailyWage ?? this.dailyWage,
        totalDaysWorked: totalDaysWorked ?? this.totalDaysWorked,
        totalPaid: totalPaid ?? this.totalPaid,
        role: role ?? this.role,
        createdAt: createdAt,
      );
}

import 'package:uuid/uuid.dart';

class Customer {
  final String id;
  final String symbolNumber;
  final String name;
  final String date;
  final String? imagePath;
  final String address;
  final String mobileNo;
  final int numberOfChicks;
  final double chickenWeight;
  final double chickenRate;
  final double average;
  final double depositAmount;
  final double remainingAmount;
  final String paymentMode;
  final String createdAt;

  Customer({
    String? id,
    required this.symbolNumber,
    required this.name,
    required this.date,
    this.imagePath,
    required this.address,
    required this.mobileNo,
    this.numberOfChicks = 0,
    required this.chickenWeight,
    required this.chickenRate,
    required this.depositAmount,
    required this.paymentMode,
    String? createdAt,
  })  : id = id ?? const Uuid().v4(),
        average = numberOfChicks > 0 ? chickenWeight / numberOfChicks : 0.0,
        remainingAmount = (chickenWeight * chickenRate) - depositAmount,
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  double get totalAmount => chickenWeight * chickenRate;

  Map<String, dynamic> toMap() => {
        'id': id,
        'symbolNumber': symbolNumber,
        'name': name,
        'date': date,
        'imagePath': imagePath,
        'address': address,
        'mobileNo': mobileNo,
        'numberOfChicks': numberOfChicks,
        'chickenWeight': chickenWeight,
        'chickenRate': chickenRate,
        'average': average,
        'depositAmount': depositAmount,
        'remainingAmount': remainingAmount,
        'paymentMode': paymentMode,
        'createdAt': createdAt,
      };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'],
        symbolNumber: map['symbolNumber'] ?? '',
        name: map['name'],
        date: map['date'],
        imagePath: map['imagePath'],
        address: map['address'] ?? '',
        mobileNo: map['mobileNo'] ?? '',
        numberOfChicks: (map['numberOfChicks'] as num?)?.toInt() ?? 0,
        chickenWeight: (map['chickenWeight'] as num?)?.toDouble() ?? 0,
        chickenRate: (map['chickenRate'] as num?)?.toDouble() ?? 0,
        depositAmount: (map['depositAmount'] as num?)?.toDouble() ?? 0,
        paymentMode: map['paymentMode'] ?? 'Cash',
        createdAt: map['createdAt'],
      );

  Customer copyWith({
    String? symbolNumber,
    String? name,
    String? date,
    String? imagePath,
    String? address,
    String? mobileNo,
    int? numberOfChicks,
    double? chickenWeight,
    double? chickenRate,
    double? depositAmount,
    String? paymentMode,
  }) =>
      Customer(
        id: id,
        symbolNumber: symbolNumber ?? this.symbolNumber,
        name: name ?? this.name,
        date: date ?? this.date,
        imagePath: imagePath ?? this.imagePath,
        address: address ?? this.address,
        mobileNo: mobileNo ?? this.mobileNo,
        numberOfChicks: numberOfChicks ?? this.numberOfChicks,
        chickenWeight: chickenWeight ?? this.chickenWeight,
        chickenRate: chickenRate ?? this.chickenRate,
        depositAmount: depositAmount ?? this.depositAmount,
        paymentMode: paymentMode ?? this.paymentMode,
        createdAt: createdAt,
      );
}

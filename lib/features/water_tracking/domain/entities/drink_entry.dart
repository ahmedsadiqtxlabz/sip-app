import 'package:equatable/equatable.dart';

class DrinkEntry extends Equatable {
  final String id;
  final int amount; // Stored in ml
  final String drinkType; // 'water', 'coffee', 'tea', 'juice', 'soda'
  final DateTime timestamp;

  const DrinkEntry({
    required this.id,
    required this.amount,
    required this.drinkType,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'drinkType': drinkType,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory DrinkEntry.fromMap(Map<dynamic, dynamic> map) {
    return DrinkEntry(
      id: map['id'] as String,
      amount: (map['amount'] as num).toInt(),
      drinkType: (map['drinkType'] as String?) ?? 'water',
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  @override
  List<Object?> get props => [id, amount, drinkType, timestamp];
}


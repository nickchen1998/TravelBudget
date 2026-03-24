import '../constants/categories.dart';

class Expense {
  final int? id;
  final int tripId;
  final String title;
  final double amount;
  final String currency;
  final double? convertedAmount;
  final double? exchangeRate;
  final ExpenseCategory category;
  final String? note;
  final String? receiptImagePath;
  final DateTime date;
  final DateTime createdAt;

  Expense({
    this.id,
    required this.tripId,
    required this.title,
    required this.amount,
    required this.currency,
    this.convertedAmount,
    this.exchangeRate,
    required this.category,
    this.note,
    this.receiptImagePath,
    required this.date,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Expense copyWith({
    int? id,
    int? tripId,
    String? title,
    double? amount,
    String? currency,
    double? convertedAmount,
    double? exchangeRate,
    ExpenseCategory? category,
    String? note,
    String? receiptImagePath,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      convertedAmount: convertedAmount ?? this.convertedAmount,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      category: category ?? this.category,
      note: note ?? this.note,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'title': title,
      'amount': amount,
      'currency': currency,
      'converted_amount': convertedAmount,
      'exchange_rate': exchangeRate,
      'category': category.name,
      'note': note,
      'receipt_image_path': receiptImagePath,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      tripId: map['trip_id'] as int,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      convertedAmount: map['converted_amount'] != null
          ? (map['converted_amount'] as num).toDouble()
          : null,
      exchangeRate: map['exchange_rate'] != null
          ? (map['exchange_rate'] as num).toDouble()
          : null,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExpenseCategory.food,
      ),
      note: map['note'] as String?,
      receiptImagePath: map['receipt_image_path'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

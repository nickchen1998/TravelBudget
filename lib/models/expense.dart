import '../constants/categories.dart';
import '../constants/payment_methods.dart';

class Expense {
  final int? id;
  final String? uuid;
  final String? createdBy;
  final String? syncedAt;
  final bool isDirty;
  final int tripId;
  final String? tripUuid;
  final String title;
  final double amount;
  final String currency;
  final double? convertedAmount;
  final double? exchangeRate;
  final ExpenseCategory category;
  final PaymentMethod? paymentMethod;
  final String? paidBy; // user UUID of who paid (for split bill)
  final String? splitType; // 'equal' | 'custom' | null
  final String? note;
  final String? receiptImagePath;
  final DateTime date;
  final DateTime createdAt;

  Expense({
    this.id,
    this.uuid,
    this.createdBy,
    this.syncedAt,
    this.isDirty = true,
    required this.tripId,
    this.tripUuid,
    required this.title,
    required this.amount,
    required this.currency,
    this.convertedAmount,
    this.exchangeRate,
    required this.category,
    this.paymentMethod,
    this.paidBy,
    this.splitType,
    this.note,
    this.receiptImagePath,
    required this.date,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Expense copyWith({
    int? id,
    String? uuid,
    String? createdBy,
    String? syncedAt,
    bool? isDirty,
    int? tripId,
    String? tripUuid,
    String? title,
    double? amount,
    String? currency,
    double? convertedAmount,
    double? exchangeRate,
    ExpenseCategory? category,
    PaymentMethod? paymentMethod,
    String? paidBy,
    String? splitType,
    String? note,
    String? receiptImagePath,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      createdBy: createdBy ?? this.createdBy,
      syncedAt: syncedAt ?? this.syncedAt,
      isDirty: isDirty ?? this.isDirty,
      tripId: tripId ?? this.tripId,
      tripUuid: tripUuid ?? this.tripUuid,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      convertedAmount: convertedAmount ?? this.convertedAmount,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidBy: paidBy ?? this.paidBy,
      splitType: splitType ?? this.splitType,
      note: note ?? this.note,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'created_by': createdBy,
      'synced_at': syncedAt,
      'is_dirty': isDirty ? 1 : 0,
      'trip_id': tripId,
      'title': title,
      'amount': amount,
      'currency': currency,
      'converted_amount': convertedAmount,
      'exchange_rate': exchangeRate,
      'category': category.name,
      'payment_method': paymentMethod?.name,
      'paid_by': paidBy,
      'split_type': splitType,
      'note': note,
      'receipt_image_path': receiptImagePath,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      uuid: map['uuid'] as String?,
      createdBy: map['created_by'] as String?,
      syncedAt: map['synced_at'] as String?,
      isDirty: (map['is_dirty'] as int? ?? 1) == 1,
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
      paymentMethod: map['payment_method'] != null
          ? PaymentMethod.values.cast<PaymentMethod?>().firstWhere(
              (e) => e?.name == map['payment_method'],
              orElse: () => null,
            )
          : null,
      paidBy: map['paid_by'] as String?,
      splitType: map['split_type'] as String?,
      note: map['note'] as String?,
      receiptImagePath: map['receipt_image_path'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory Expense.fromSupabase(Map<String, dynamic> map, int localTripId) {
    return Expense(
      uuid: map['id'] as String,
      createdBy: map['created_by'] as String?,
      isDirty: false,
      tripId: localTripId,
      tripUuid: map['trip_id'] as String?,
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
      paymentMethod: map['payment_method'] != null
          ? PaymentMethod.values.cast<PaymentMethod?>().firstWhere(
              (e) => e?.name == map['payment_method'],
              orElse: () => null,
            )
          : null,
      paidBy: map['paid_by'] as String?,
      splitType: map['split_type'] as String?,
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toSupabaseMap(String userId, String tripUuid) {
    return {
      if (uuid != null) 'id': uuid,
      'trip_id': tripUuid,
      'created_by': userId,
      'title': title,
      'amount': amount,
      'currency': currency,
      'converted_amount': convertedAmount,
      'exchange_rate': exchangeRate,
      'category': category.name,
      if (paymentMethod != null) 'payment_method': paymentMethod!.name,
      if (paidBy != null) 'paid_by': paidBy,
      'split_type': splitType,
      'note': note,
      'date': date.toIso8601String().substring(0, 10),
    };
  }
}

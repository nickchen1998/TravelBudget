class Trip {
  final int? id;
  final String name;
  final double budget;
  final String baseCurrency;
  final String targetCurrency;
  final DateTime startDate;
  final DateTime endDate;
  final String? coverImagePath;
  final DateTime createdAt;

  Trip({
    this.id,
    required this.name,
    required this.budget,
    required this.baseCurrency,
    required this.targetCurrency,
    required this.startDate,
    required this.endDate,
    this.coverImagePath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get totalDays => endDate.difference(startDate).inDays + 1;

  Trip copyWith({
    int? id,
    String? name,
    double? budget,
    String? baseCurrency,
    String? targetCurrency,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImagePath,
    DateTime? createdAt,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      budget: budget ?? this.budget,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      targetCurrency: targetCurrency ?? this.targetCurrency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'budget': budget,
      'base_currency': baseCurrency,
      'target_currency': targetCurrency,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'cover_image_path': coverImagePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as int?,
      name: map['name'] as String,
      budget: (map['budget'] as num).toDouble(),
      baseCurrency: map['base_currency'] as String,
      targetCurrency: map['target_currency'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      coverImagePath: map['cover_image_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

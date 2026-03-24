class ExchangeRate {
  final String baseCurrency;
  final String targetCurrency;
  final double rate;
  final DateTime fetchedAt;

  ExchangeRate({
    required this.baseCurrency,
    required this.targetCurrency,
    required this.rate,
    required this.fetchedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'base_currency': baseCurrency,
      'target_currency': targetCurrency,
      'rate': rate,
      'fetched_at': fetchedAt.toIso8601String(),
    };
  }

  factory ExchangeRate.fromMap(Map<String, dynamic> map) {
    return ExchangeRate(
      baseCurrency: map['base_currency'] as String,
      targetCurrency: map['target_currency'] as String,
      rate: (map['rate'] as num).toDouble(),
      fetchedAt: DateTime.parse(map['fetched_at'] as String),
    );
  }
}

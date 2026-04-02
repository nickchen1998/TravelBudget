class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;

  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
  });
}

const List<CurrencyInfo> supportedCurrencies = [
  CurrencyInfo(code: 'TWD', name: '新台幣', symbol: 'NT\$'),
  CurrencyInfo(code: 'JPY', name: '日圓', symbol: '¥'),
  CurrencyInfo(code: 'USD', name: '美元', symbol: '\$'),
  CurrencyInfo(code: 'EUR', name: '歐元', symbol: '€'),
  CurrencyInfo(code: 'GBP', name: '英鎊', symbol: '£'),
  CurrencyInfo(code: 'KRW', name: '韓元', symbol: '₩'),
  CurrencyInfo(code: 'CNY', name: '人民幣', symbol: '¥'),
  CurrencyInfo(code: 'HKD', name: '港幣', symbol: 'HK\$'),
  CurrencyInfo(code: 'THB', name: '泰銖', symbol: '฿'),
  CurrencyInfo(code: 'SGD', name: '新加坡幣', symbol: 'S\$'),
  CurrencyInfo(code: 'MYR', name: '馬來西亞令吉', symbol: 'RM'),
  CurrencyInfo(code: 'AUD', name: '澳幣', symbol: 'A\$'),
  CurrencyInfo(code: 'CAD', name: '加幣', symbol: 'C\$'),
  CurrencyInfo(code: 'CHF', name: '瑞士法郎', symbol: 'CHF'),
  CurrencyInfo(code: 'VND', name: '越南盾', symbol: '₫'),
  CurrencyInfo(code: 'PHP', name: '菲律賓披索', symbol: '₱'),
];

/// 格式化數字為千分位字串（例如 12345 → "12,345"）
String formatAmount(num value, {int decimals = 0}) {
  final fixed = value.toStringAsFixed(decimals);
  if (decimals == 0) {
    // 整數：加千分位
    final isNeg = value < 0;
    final digits = isNeg ? fixed.substring(1) : fixed;
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return isNeg ? '-${buf.toString()}' : buf.toString();
  }
  // 有小數：整數部分加千分位
  final parts = fixed.split('.');
  final isNeg = value < 0;
  final digits = isNeg ? parts[0].substring(1) : parts[0];
  final buf = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  final intPart = isNeg ? '-${buf.toString()}' : buf.toString();
  return '$intPart.${parts[1]}';
}

String getCurrencySymbol(String code) {
  return supportedCurrencies
      .firstWhere(
        (c) => c.code == code,
        orElse: () => CurrencyInfo(code: code, name: code, symbol: code),
      )
      .symbol;
}

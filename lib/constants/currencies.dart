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

String getCurrencySymbol(String code) {
  return supportedCurrencies
      .firstWhere(
        (c) => c.code == code,
        orElse: () => CurrencyInfo(code: code, name: code, symbol: code),
      )
      .symbol;
}

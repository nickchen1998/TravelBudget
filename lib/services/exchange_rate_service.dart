import 'dart:convert';
import 'package:http/http.dart' as http;
import '../db/expense_dao.dart';
import '../models/exchange_rate.dart';

class ExchangeRateService {
  static const String _baseUrl = 'https://open.er-api.com/v6/latest';
  static const Duration _cacheMaxAge = Duration(days: 1);

  final ExpenseDao _dao = ExpenseDao();

  Future<double> getRate(String from, String to) async {
    if (from == to) return 1.0;

    // Check cache first
    final cached = await _dao.getCachedRate(from, to);
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _cacheMaxAge) {
      return cached.rate;
    }

    // Try fetching from API
    try {
      final uri = Uri.parse('$_baseUrl/$from');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['result'] == 'success') {
          final rates = data['rates'] as Map<String, dynamic>;
          if (rates.containsKey(to)) {
            final rate = (rates[to] as num).toDouble();

            // Cache the rate
            await _dao.upsertRate(ExchangeRate(
              baseCurrency: from,
              targetCurrency: to,
              rate: rate,
              fetchedAt: DateTime.now(),
            ));

            return rate;
          }
        }
      }
    } catch (_) {
      // Network error - fall back to cache even if stale
    }

    // Return stale cache if available
    if (cached != null) return cached.rate;

    // No cache at all - return 1.0 as last resort
    return 1.0;
  }

  Future<double> convert(double amount, String from, String to) async {
    final rate = await getRate(from, to);
    return amount * rate;
  }
}

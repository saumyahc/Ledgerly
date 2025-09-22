import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service to fetch live crypto rates using CoinGecko public API
class CryptoApiService {
  /// Get live rates for a list of crypto symbols (e.g. ['BTC', 'ETH']) against a target currency (e.g. 'USD')
  /// Returns a map: { 'BTC': 27123.0, 'ETH': 1800.0, ... }
  static Future<Map<String, double>> getLiveRates({
    required List<String> symbols,
    required String target,
  }) async {
    // CoinGecko uses lowercase ids and currency codes
    final ids = symbols.map((s) => _symbolToId[s.toUpperCase()] ?? s.toLowerCase()).join(',');
    final vsCurrency = target.toLowerCase();
    final url =
        'https://api.coingecko.com/api/v3/simple/price?ids=$ids&vs_currencies=$vsCurrency';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch crypto rates');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final Map<String, double> rates = {};
    for (final symbol in symbols) {
      final id = _symbolToId[symbol.toUpperCase()] ?? symbol.toLowerCase();
      final price = data[id]?[vsCurrency];
      if (price != null && price is num) {
        rates[symbol] = price.toDouble();
      } else {
        rates[symbol] = 0.0;
      }
    }
    return rates;
  }

  // Mapping from symbol to CoinGecko id
  static const Map<String, String> _symbolToId = {
    'BTC': 'bitcoin',
    'ETH': 'ethereum',
    'XRP': 'ripple',
    'LTC': 'litecoin',
    'BCH': 'bitcoin-cash',
    'ADA': 'cardano',
    'DOT': 'polkadot',
    'LINK': 'chainlink',
    'UNI': 'uniswap',
    'DOGE': 'dogecoin',
    // Add more as needed
  };
}

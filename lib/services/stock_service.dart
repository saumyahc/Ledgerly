import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/stock_models.dart';

class StockService {
  static const Duration _timeout = Duration(seconds: 10);
  static const Duration _cacheExpiry = Duration(minutes: 1);
  
  final Map<String, StockQuote> _quoteCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, List<CandleData>> _candleCache = {};

  // Popular stock symbols for demo
  static const List<String> popularSymbols = [
    'AAPL', 'GOOGL', 'MSFT', 'AMZN', 'TSLA', 
    'META', 'NVDA', 'NFLX', 'AMD', 'INTC'
  ];

  Future<StockQuote?> getQuote(String symbol) async {
    try {
      // Check cache first
      if (_isQuoteCached(symbol)) {
        return _quoteCache[symbol];
      }

      final uri = Uri.parse(FinnhubConstants.quoteUrl(symbol));
      print(uri);
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Check if response has valid data
        if (data['c'] != null && data['c'] != 0) {
          final quote = StockQuote.fromJson(data, symbol);
          _cacheQuote(symbol, quote);
          return quote;
        }
      }
      
      print('Failed to fetch quote for $symbol: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error fetching quote for $symbol: $e');
      return null;
    }
  }

  Future<List<CandleData>> getCandleData(
    String symbol, {
    String resolution = 'D',
    int? daysBack = 30,
  }) async {
    try {
      final cacheKey = '${symbol}_${resolution}_$daysBack';
      
      // Check cache
      if (_candleCache.containsKey(cacheKey)) {
        final cached = _candleCache[cacheKey]!;
        return cached;
      }
      
      final now = DateTime.now();
      final from = now.subtract(Duration(days: daysBack ?? 30)).millisecondsSinceEpoch ~/ 1000;
      final to = now.millisecondsSinceEpoch ~/ 1000;
      final uri = Uri.parse(FinnhubConstants.candleUrl(symbol, resolution, from, to));
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['s'] == 'ok') {
          final List<CandleData> candles = [];
          final List<dynamic> t = data['t'] ?? [];
          final List<dynamic> o = data['o'] ?? [];
          final List<dynamic> h = data['h'] ?? [];
          final List<dynamic> l = data['l'] ?? [];
          final List<dynamic> c = data['c'] ?? [];
          final List<dynamic> v = data['v'] ?? [];
          for (int i = 0; i < t.length; i++) {
            candles.add(CandleData(
              timestamp: DateTime.fromMillisecondsSinceEpoch((t[i] as int) * 1000),
              open: (o[i] as num?)?.toDouble() ?? 0.0,
              high: (h[i] as num?)?.toDouble() ?? 0.0,
              low: (l[i] as num?)?.toDouble() ?? 0.0,
              close: (c[i] as num?)?.toDouble() ?? 0.0,
              volume: (v[i] as num?)?.toInt() ?? 0,
            ));
          }
          _candleCache[cacheKey] = candles;
          return candles;
        }
      }
      print('Failed to fetch candle data for $symbol: ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error fetching candle data for $symbol: $e');
      return [];
    }
  }

  bool _isQuoteCached(String symbol) {
    if (!_quoteCache.containsKey(symbol)) return false;
    final cachedAt = _cacheTimestamps[symbol];
    if (cachedAt == null) return false;
    return DateTime.now().difference(cachedAt) < _cacheExpiry;
  }

  void _cacheQuote(String symbol, StockQuote quote) {
    _quoteCache[symbol] = quote;
    _cacheTimestamps[symbol] = DateTime.now();
  }
}

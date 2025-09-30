class StockQuote {
  final String symbol;
  final double currentPrice;
  final double change;
  final double changePercent;
  final double highPrice;
  final double lowPrice;
  final double openPrice;
  final double previousClose;
  final DateTime timestamp;

  StockQuote({
    required this.symbol,
    required this.currentPrice,
    required this.change,
    required this.changePercent,
    required this.highPrice,
    required this.lowPrice,
    required this.openPrice,
    required this.previousClose,
    required this.timestamp,
  });

  factory StockQuote.fromJson(Map<String, dynamic> json, String symbol) {
    final double current = (json['c'] as num?)?.toDouble() ?? 0.0;
    final double high = (json['h'] as num?)?.toDouble() ?? 0.0;
    final double low = (json['l'] as num?)?.toDouble() ?? 0.0;
    final double open = (json['o'] as num?)?.toDouble() ?? 0.0;
    final double previousClose = (json['pc'] as num?)?.toDouble() ?? 0.0;
    final double change = (json['d'] as num?)?.toDouble() ?? 0.0;
    final double changePercent = (json['dp'] as num?)?.toDouble() ?? 0.0;

    return StockQuote(
      symbol: symbol,
      currentPrice: current,
      change: change,
      changePercent: changePercent,
      highPrice: high,
      lowPrice: low,
      openPrice: open,
      previousClose: previousClose,
      timestamp: DateTime.now(),
    );
  }

  bool get isPositive => change >= 0;
}

class CandleData {
  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  CandleData({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

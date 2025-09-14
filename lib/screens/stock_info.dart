import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../theme.dart';

class StockInfoPage extends StatefulWidget {
  const StockInfoPage({super.key});

  @override
  State<StockInfoPage> createState() => _StockInfoPageState();
}

class _StockInfoPageState extends State<StockInfoPage> {
  // Curated list similar to the reference UI (no user symbols kept)
  final List<_SymbolInfo> _symbols = const <_SymbolInfo>[
    _SymbolInfo(
      symbol: 'DJI',
      display: 'Dow Jones',
      subtitle: 'Dow Jones Industrial Average',
      finnhubSymbol: '^DJI',
      isIndex: true,
    ),
    _SymbolInfo(
      symbol: 'GSPC',
      display: 'S&P 500',
      subtitle: "Standard & Poor's 500",
      finnhubSymbol: '^GSPC',
      isIndex: true,
    ),
    _SymbolInfo(
      symbol: 'FTSE',
      display: '^FTSE',
      subtitle: 'FTSE 100',
      finnhubSymbol: '^FTSE',
      isIndex: true,
    ),
    _SymbolInfo(
      symbol: 'IXIC',
      display: 'NASDAQ',
      subtitle: 'NASDAQ Composite',
      finnhubSymbol: '^IXIC',
      isIndex: true,
    ),
    _SymbolInfo(
      symbol: 'RUT',
      display: 'Russell 2000',
      subtitle: 'Small-cap index',
      finnhubSymbol: '^RUT',
      isIndex: true,
    ),
    _SymbolInfo(
      symbol: 'GE',
      display: 'GE',
      subtitle: 'GE Aerospace',
      finnhubSymbol: 'GE',
    ),
    _SymbolInfo(
      symbol: 'AAPL',
      display: 'AAPL',
      subtitle: 'Apple Inc.',
      finnhubSymbol: 'AAPL',
    ),
    _SymbolInfo(
      symbol: 'MSFT',
      display: 'MSFT',
      subtitle: 'Microsoft Corporation',
      finnhubSymbol: 'MSFT',
    ),
    _SymbolInfo(
      symbol: 'GOOGL',
      display: 'GOOGL',
      subtitle: 'Alphabet Inc.',
      finnhubSymbol: 'GOOGL',
    ),
    _SymbolInfo(
      symbol: 'AMZN',
      display: 'AMZN',
      subtitle: 'Amazon.com, Inc.',
      finnhubSymbol: 'AMZN',
    ),
    _SymbolInfo(
      symbol: 'TSLA',
      display: 'TSLA',
      subtitle: 'Tesla, Inc.',
      finnhubSymbol: 'TSLA',
    ),
    _SymbolInfo(
      symbol: 'NKE',
      display: 'NKE',
      subtitle: 'NIKE, Inc.',
      finnhubSymbol: 'NKE',
    ),
    _SymbolInfo(
      symbol: 'META',
      display: 'META',
      subtitle: 'Meta Platforms, Inc.',
      finnhubSymbol: 'META',
    ),
    _SymbolInfo(
      symbol: 'NVDA',
      display: 'NVDA',
      subtitle: 'NVIDIA Corporation',
      finnhubSymbol: 'NVDA',
    ),
    _SymbolInfo(
      symbol: 'NFLX',
      display: 'NFLX',
      subtitle: 'Netflix, Inc.',
      finnhubSymbol: 'NFLX',
    ),
    _SymbolInfo(
      symbol: 'AMD',
      display: 'AMD',
      subtitle: 'Advanced Micro Devices, Inc.',
      finnhubSymbol: 'AMD',
    ),
    _SymbolInfo(
      symbol: 'INTC',
      display: 'INTC',
      subtitle: 'Intel Corporation',
      finnhubSymbol: 'INTC',
    ),
    _SymbolInfo(
      symbol: 'ORCL',
      display: 'ORCL',
      subtitle: 'Oracle Corporation',
      finnhubSymbol: 'ORCL',
    ),
    _SymbolInfo(
      symbol: 'CRM',
      display: 'CRM',
      subtitle: 'Salesforce, Inc.',
      finnhubSymbol: 'CRM',
    ),
    _SymbolInfo(
      symbol: 'PYPL',
      display: 'PYPL',
      subtitle: 'PayPal Holdings, Inc.',
      finnhubSymbol: 'PYPL',
    ),
    _SymbolInfo(
      symbol: 'PEP',
      display: 'PEP',
      subtitle: 'PepsiCo, Inc.',
      finnhubSymbol: 'PEP',
    ),
    _SymbolInfo(
      symbol: 'KO',
      display: 'KO',
      subtitle: 'Coca-Cola Company',
      finnhubSymbol: 'KO',
    ),
    _SymbolInfo(
      symbol: 'JPM',
      display: 'JPM',
      subtitle: 'JPMorgan Chase & Co.',
      finnhubSymbol: 'JPM',
    ),
    _SymbolInfo(
      symbol: 'BAC',
      display: 'BAC',
      subtitle: 'Bank of America Corporation',
      finnhubSymbol: 'BAC',
    ),
    _SymbolInfo(
      symbol: 'V',
      display: 'V',
      subtitle: 'Visa Inc.',
      finnhubSymbol: 'V',
    ),
    _SymbolInfo(
      symbol: 'MA',
      display: 'MA',
      subtitle: 'Mastercard Incorporated',
      finnhubSymbol: 'MA',
    ),
    _SymbolInfo(
      symbol: 'DIS',
      display: 'DIS',
      subtitle: 'Walt Disney Company',
      finnhubSymbol: 'DIS',
    ),
    _SymbolInfo(
      symbol: 'PFE',
      display: 'PFE',
      subtitle: 'Pfizer Inc.',
      finnhubSymbol: 'PFE',
    ),
    _SymbolInfo(
      symbol: 'JNJ',
      display: 'JNJ',
      subtitle: 'Johnson & Johnson',
      finnhubSymbol: 'JNJ',
    ),
    _SymbolInfo(
      symbol: 'WMT',
      display: 'WMT',
      subtitle: 'Walmart Inc.',
      finnhubSymbol: 'WMT',
    ),
    _SymbolInfo(
      symbol: 'T',
      display: 'T',
      subtitle: 'AT&T Inc.',
      finnhubSymbol: 'T',
    ),
    _SymbolInfo(
      symbol: 'VZ',
      display: 'VZ',
      subtitle: 'Verizon Communications Inc.',
      finnhubSymbol: 'VZ',
    ),
    _SymbolInfo(
      symbol: 'XOM',
      display: 'XOM',
      subtitle: 'Exxon Mobil Corporation',
      finnhubSymbol: 'XOM',
    ),
    _SymbolInfo(
      symbol: 'CVX',
      display: 'CVX',
      subtitle: 'Chevron Corporation',
      finnhubSymbol: 'CVX',
    ),
    _SymbolInfo(
      symbol: 'BABA',
      display: 'BABA',
      subtitle: 'Alibaba Group Holding Limited',
      finnhubSymbol: 'BABA',
    ),
    _SymbolInfo(
      symbol: 'SHOP',
      display: 'SHOP',
      subtitle: 'Shopify Inc.',
      finnhubSymbol: 'SHOP',
    ),
    _SymbolInfo(
      symbol: 'UBER',
      display: 'UBER',
      subtitle: 'Uber Technologies, Inc.',
      finnhubSymbol: 'UBER',
    ),
    _SymbolInfo(
      symbol: 'ADBE',
      display: 'ADBE',
      subtitle: 'Adobe Inc.',
      finnhubSymbol: 'ADBE',
    ),
    _SymbolInfo(
      symbol: 'CSCO',
      display: 'CSCO',
      subtitle: 'Cisco Systems, Inc.',
      finnhubSymbol: 'CSCO',
    ),
    _SymbolInfo(
      symbol: 'ABNB',
      display: 'ABNB',
      subtitle: 'Airbnb, Inc.',
      finnhubSymbol: 'ABNB',
    ),
    _SymbolInfo(
      symbol: 'ZM',
      display: 'ZM',
      subtitle: 'Zoom Video Communications, Inc.',
      finnhubSymbol: 'ZM',
    ),
    _SymbolInfo(
      symbol: 'SNOW',
      display: 'SNOW',
      subtitle: 'Snowflake Inc.',
      finnhubSymbol: 'SNOW',
    ),
    _SymbolInfo(
      symbol: 'PLTR',
      display: 'PLTR',
      subtitle: 'Palantir Technologies Inc.',
      finnhubSymbol: 'PLTR',
    ),
    _SymbolInfo(
      symbol: 'SQ',
      display: 'SQ',
      subtitle: 'Block, Inc.',
      finnhubSymbol: 'SQ',
    ),
    _SymbolInfo(
      symbol: 'SHOP',
      display: 'SHOP',
      subtitle: 'Shopify Inc.',
      finnhubSymbol: 'SHOP',
    ),
    _SymbolInfo(
      symbol: 'RBLX',
      display: 'RBLX',
      subtitle: 'Roblox Corporation',
      finnhubSymbol: 'RBLX',
    ),
    _SymbolInfo(
      symbol: 'MRVL',
      display: 'MRVL',
      subtitle: 'Marvell Technology, Inc.',
      finnhubSymbol: 'MRVL',
    ),
    _SymbolInfo(
      symbol: 'QCOM',
      display: 'QCOM',
      subtitle: 'QUALCOMM Incorporated',
      finnhubSymbol: 'QCOM',
    ),
    _SymbolInfo(
      symbol: 'MU',
      display: 'MU',
      subtitle: 'Micron Technology, Inc.',
      finnhubSymbol: 'MU',
    ),
    _SymbolInfo(
      symbol: 'AVGO',
      display: 'AVGO',
      subtitle: 'Broadcom Inc.',
      finnhubSymbol: 'AVGO',
    ),
    _SymbolInfo(
      symbol: 'TSM',
      display: 'TSM',
      subtitle: 'Taiwan Semiconductor Manufacturing Company',
      finnhubSymbol: 'TSM',
    ),
    _SymbolInfo(
      symbol: 'IBM',
      display: 'IBM',
      subtitle: 'International Business Machines Corporation',
      finnhubSymbol: 'IBM',
    ),
    _SymbolInfo(
      symbol: 'SAP',
      display: 'SAP',
      subtitle: 'SAP SE',
      finnhubSymbol: 'SAP',
    ),
    _SymbolInfo(
      symbol: 'PG',
      display: 'PG',
      subtitle: 'Procter & Gamble Company',
      finnhubSymbol: 'PG',
    ),
    _SymbolInfo(
      symbol: 'MCD',
      display: 'MCD',
      subtitle: 'McDonald\'s Corporation',
      finnhubSymbol: 'MCD',
    ),
    _SymbolInfo(
      symbol: 'SBUX',
      display: 'SBUX',
      subtitle: 'Starbucks Corporation',
      finnhubSymbol: 'SBUX',
    ),
    _SymbolInfo(
      symbol: 'COST',
      display: 'COST',
      subtitle: 'Costco Wholesale Corporation',
      finnhubSymbol: 'COST',
    ),
    _SymbolInfo(
      symbol: 'HD',
      display: 'HD',
      subtitle: 'Home Depot, Inc.',
      finnhubSymbol: 'HD',
    ),
    _SymbolInfo(
      symbol: 'LOW',
      display: 'LOW',
      subtitle: 'Lowe\'s Companies, Inc.',
      finnhubSymbol: 'LOW',
    ),
    _SymbolInfo(
      symbol: 'TGT',
      display: 'TGT',
      subtitle: 'Target Corporation',
      finnhubSymbol: 'TGT',
    ),
    _SymbolInfo(
      symbol: 'MRK',
      display: 'MRK',
      subtitle: 'Merck & Co., Inc.',
      finnhubSymbol: 'MRK',
    ),
    _SymbolInfo(
      symbol: 'ABT',
      display: 'ABT',
      subtitle: 'Abbott Laboratories',
      finnhubSymbol: 'ABT',
    ),
    _SymbolInfo(
      symbol: 'BA',
      display: 'BA',
      subtitle: 'The Boeing Company',
      finnhubSymbol: 'BA',
    ),
    _SymbolInfo(
      symbol: 'CAT',
      display: 'CAT',
      subtitle: 'Caterpillar Inc.',
      finnhubSymbol: 'CAT',
    ),
    _SymbolInfo(
      symbol: 'GS',
      display: 'GS',
      subtitle: 'The Goldman Sachs Group, Inc.',
      finnhubSymbol: 'GS',
    ),
    _SymbolInfo(
      symbol: 'MS',
      display: 'MS',
      subtitle: 'Morgan Stanley',
      finnhubSymbol: 'MS',
    ),
    _SymbolInfo(
      symbol: 'AAL',
      display: 'AAL',
      subtitle: 'American Airlines Group Inc.',
      finnhubSymbol: 'AAL',
    ),
    _SymbolInfo(
      symbol: 'DAL',
      display: 'DAL',
      subtitle: 'Delta Air Lines, Inc.',
      finnhubSymbol: 'DAL',
    ),
    _SymbolInfo(
      symbol: 'UAL',
      display: 'UAL',
      subtitle: 'United Airlines Holdings, Inc.',
      finnhubSymbol: 'UAL',
    ),
    _SymbolInfo(
      symbol: 'F',
      display: 'F',
      subtitle: 'Ford Motor Company',
      finnhubSymbol: 'F',
    ),
    _SymbolInfo(
      symbol: 'GM',
      display: 'GM',
      subtitle: 'General Motors Company',
      finnhubSymbol: 'GM',
    ),
    _SymbolInfo(
      symbol: 'BP',
      display: 'BP',
      subtitle: 'BP p.l.c.',
      finnhubSymbol: 'BP',
    ),
    _SymbolInfo(
      symbol: 'SHEL',
      display: 'SHEL',
      subtitle: 'Shell plc',
      finnhubSymbol: 'SHEL',
    ),
  ];

  final Map<String, _Quote> _quotesBySymbol = <String, _Quote>{};
  Timer? _refreshTimer;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  Timer? _debounce;
  // Dynamic loading
  final List<_SymbolInfo> _dynamicSymbols = <_SymbolInfo>[];
  bool _isLoadingMore = false;
  int _page = 0;
  static const int _pageSize = 30;
  String _exchange = 'US';
  final List<String> _exchanges = <String>['US', 'NYSE', 'NASDAQ', 'LSE', 'TO'];

  @override
  void initState() {
    super.initState();
    _initialLoad();
    _startAutoRefresh();
  }

  List<_SymbolInfo> get _filteredSymbols {
    final List<_SymbolInfo> base = _allSymbols;
    if (_query.isEmpty) return base;
    final String q = _query.toLowerCase();
    return base.where((s) {
      return s.display.toLowerCase().contains(q) ||
          s.subtitle.toLowerCase().contains(q) ||
          s.symbol.toLowerCase().contains(q) ||
          s.finnhubSymbol.toLowerCase().contains(q);
    }).toList();
  }

  List<_SymbolInfo> get _allSymbols {
    final int takeCount = _page * _pageSize;
    final List<_SymbolInfo> dyn = takeCount <= 0
        ? <_SymbolInfo>[]
        : _dynamicSymbols.sublist(
            0,
            takeCount > _dynamicSymbols.length
                ? _dynamicSymbols.length
                : takeCount,
          );
    return <_SymbolInfo>[..._symbols, ...dyn];
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialLoad() async {
    if (FinnhubConstants.apiKey.isEmpty) {
      setState(() {
        _error = 'Missing Finnhub API key. Set it in FinnhubConstants.apiKey.';
      });
      return;
    }
    await _refreshAll();
    await _loadMoreSymbols();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _refreshAll();
    });
  }

  Future<void> _refreshAll() async {
    try {
      setState(() => _error = null);
      final List<_SymbolInfo> base = _allSymbols;
      final futures = base.map((s) => _fetchQuote(s.finnhubSymbol));
      final List<_Quote?> results = await Future.wait(futures);
      for (int i = 0; i < base.length; i++) {
        final _SymbolInfo info = base[i];
        final _Quote? q = results[i];
        if (q != null) {
          _quotesBySymbol[info.finnhubSymbol] = q;
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      setState(() {
        _error = 'Failed to refresh quotes';
      });
    }
  }

  Future<void> _loadMoreSymbols() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;
    try {
      if (_dynamicSymbols.isEmpty) {
        final uri = Uri.parse(FinnhubConstants.symbolsUrl(_exchange));
        final res = await http.get(uri);
        if (res.statusCode == 200) {
          final List<dynamic> arr = jsonDecode(res.body) as List<dynamic>;
          for (final dynamic item in arr) {
            final Map<String, dynamic> m = item as Map<String, dynamic>;
            final String symbol = (m['symbol'] as String? ?? '').trim();
            final String description = (m['description'] as String? ?? '')
                .trim();
            if (symbol.isEmpty) continue;
            _dynamicSymbols.add(
              _SymbolInfo(
                symbol: symbol,
                display: symbol,
                subtitle: description.isEmpty ? symbol : description,
                finnhubSymbol: symbol,
              ),
            );
          }
        }
      }

      final int start = _page * _pageSize;
      final int end = (_page + 1) * _pageSize;
      if (start < _dynamicSymbols.length) {
        final List<_SymbolInfo> nextPage = _dynamicSymbols.sublist(
          start,
          end > _dynamicSymbols.length ? _dynamicSymbols.length : end,
        );
        for (final _SymbolInfo s in nextPage) {
          _fetchQuote(s.finnhubSymbol).then((q) {
            if (q != null) {
              _quotesBySymbol[s.finnhubSymbol] = q;
              if (mounted) setState(() {});
            }
          });
        }
        _page += 1;
        if (mounted) setState(() {});
      }
    } catch (e) {
      setState(() => _error = 'Failed to load symbols');
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<_Quote?> _fetchQuote(String symbol) async {
    try {
      final uri = Uri.parse(FinnhubConstants.quoteUrl(symbol));
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(res.body) as Map<String, dynamic>;
        final double current = (body['c'] as num?)?.toDouble() ?? 0.0;
        final double prevClose = (body['pc'] as num?)?.toDouble() ?? current;
        final double change =
            (body['d'] as num?)?.toDouble() ?? (current - prevClose);
        final double changePercent =
            (body['dp'] as num?)?.toDouble() ??
            (prevClose == 0 ? 0 : ((change / prevClose) * 100));
        final int now = DateTime.now().millisecondsSinceEpoch;
        final _Quote quote = _Quote(
          symbol: symbol,
          price: current,
          previousPrice: prevClose,
          timestampMs: now,
          volume: 0,
        );
        quote.extra = _QuoteExtra(change: change, changePercent: changePercent);
        return quote;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stocks'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildHeader(),
              const SizedBox(height: 12),
              _buildExchangeSwitcher(),
              const SizedBox(height: 12),
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildTopMovers(),
              const SizedBox(height: 12),
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  margin: const EdgeInsets.only(bottom: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(color: Colors.redAccent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification n) {
                    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                      _loadMoreSymbols();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount:
                        _filteredSymbols.length + (_isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int index) {
                      if (index >= _filteredSymbols.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final _SymbolInfo info = _filteredSymbols[index];
                      final _Quote? quote = _quotesBySymbol[info.finnhubSymbol];
                      return Glass3DCard(child: _buildQuoteTile(info, quote));
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final DateTime now = DateTime.now();
    const List<String> months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final String dateLabel = months[now.month - 1] + ' ' + now.day.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Stocks', style: Theme.of(context).textTheme.displayLarge),
        const SizedBox(height: 4),
        Text(
          dateLabel,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildExchangeSwitcher() {
    return Row(
      children: <Widget>[
        const Icon(Icons.public, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _exchanges.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (BuildContext context, int index) {
                final String ex = _exchanges[index];
                final bool selected = ex == _exchange;
                return GestureDetector(
                  onTap: () async {
                    if (selected) return;
                    setState(() {
                      _exchange = ex;
                      _dynamicSymbols.clear();
                      _page = 0;
                      _quotesBySymbol.clear();
                    });
                    await _refreshAll();
                    await _loadMoreSymbols();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.white,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.4),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ex,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteTile(_SymbolInfo info, _Quote? quote) {
    final String priceText = quote == null
        ? '—'
        : quote.price.toStringAsFixed(info.isIndex ? 2 : 2);
    final double change = quote?.extra?.change ?? 0.0;
    final double changePct = quote?.extra?.changePercent ?? 0.0;
    final bool up = change >= 0;
    final Color pillColor = up ? Colors.green : Colors.red;
    final String pillText =
        (up ? '+' : '') + changePct.toStringAsFixed(2) + '%';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      leading: Icon(Icons.show_chart, color: AppColors.primary),
      title: Text(
        info.display,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        info.subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(priceText, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: pillColor.withOpacity(0.12),
                border: Border.all(color: pillColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                pillText,
                style: TextStyle(color: pillColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      isThreeLine: true,
    );
  }

  Widget _buildTopMovers() {
    // Compute movers from available quotes
    final List<_Quote> quotes = _quotesBySymbol.values
        .where((q) => q.extra != null)
        .toList();
    quotes.sort(
      (a, b) => (b.extra!.changePercent).compareTo(a.extra!.changePercent),
    );
    final List<_Quote> top = quotes.take(5).toList();
    if (top.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Top Movers', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: top.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (BuildContext context, int index) {
              final _Quote q = top[index];
              final _SymbolInfo info = _allSymbols.firstWhere(
                (s) => s.finnhubSymbol == q.symbol,
                orElse: () => _SymbolInfo(
                  symbol: q.symbol,
                  display: q.symbol,
                  subtitle: '',
                  finnhubSymbol: q.symbol,
                ),
              );
              final bool up = (q.extra?.change ?? 0) >= 0;
              final Color pillColor = up ? Colors.green : Colors.red;
              return SizedBox(
                width: 220,
                child: Glass3DCard(
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.trending_up, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              info.display,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(q.price.toStringAsFixed(2)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: pillColor.withOpacity(0.12),
                          border: Border.all(color: pillColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          ((up ? '+' : '') +
                              (q.extra?.changePercent ?? 0).toStringAsFixed(2) +
                              '%'),
                          style: TextStyle(
                            color: pillColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        hintText: 'Search stocks (e.g., AAPL, Tesla, S&P)',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: (String value) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 250), () {
          setState(() {
            _query = value.trim();
          });
        });
      },
      textInputAction: TextInputAction.search,
    );
  }
}

class _Quote {
  _Quote({
    required this.symbol,
    this.price = 0.0,
    this.previousPrice = 0.0,
    this.timestampMs = 0,
    this.volume = 0,
  });

  final String symbol;
  double price;
  double previousPrice;
  int timestampMs;
  int volume;
  _QuoteExtra? extra;

  double get priceChange => price - previousPrice;

  void update({
    required double price,
    required int timestampMs,
    required int volume,
  }) {
    previousPrice = this.price == 0.0 ? price : this.price;
    this.price = price;
    this.timestampMs = timestampMs;
    this.volume = volume;
  }
}

class _QuoteExtra {
  _QuoteExtra({required this.change, required this.changePercent});
  final double change;
  final double changePercent;
}

class _SymbolInfo {
  const _SymbolInfo({
    required this.symbol,
    required this.display,
    required this.subtitle,
    required this.finnhubSymbol,
    this.isIndex = false,
  });
  final String symbol; // local id
  final String display; // display title
  final String subtitle; // subtext
  final String finnhubSymbol; // what we query
  final bool isIndex;
}

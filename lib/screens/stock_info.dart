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
  // Start with empty list - all symbols will be loaded dynamically from API
  final List<_SymbolInfo> _symbols = const <_SymbolInfo>[];

  final Map<String, _Quote> _quotesBySymbol = <String, _Quote>{};
  final Map<String, DateTime> _quoteTimestamps = <String, DateTime>{};
  final Map<String, List<_SymbolInfo>> _cachedSymbolsByExchange = <String, List<_SymbolInfo>>{};
  Timer? _refreshTimer;
  String? _error;
  bool _isInitialLoading = true;
  DateTime? _lastUpdated;
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

  // Optimization constants
  static const Duration _cacheExpiry = Duration(minutes: 5);
  static const Duration _autoRefreshInterval = Duration(minutes: 5);
  static const int _maxConcurrentRequests = 10;

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
    return [..._symbols, ..._dynamicSymbols];
  }

  void _initialLoad() {
    if (FinnhubConstants.apiKey == 'YOUR_API_KEY_HERE') {
      setState(() {
        _error = 'Missing Finnhub API key. Set it in FinnhubConstants.apiKey.';
      });
      return;
    }
    _refreshAll();
    _loadMoreSymbols();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      // Only refresh if app is active and symbols are visible
      if (mounted) {
        _refreshVisibleQuotes();
      }
    });
  }

  Future<void> _refreshAll() async {
    try {
      setState(() {
        _error = null;
        if (_isInitialLoading) _isInitialLoading = true; // Keep loading state
      });
      await _refreshVisibleQuotes();
      if (mounted) setState(() {
        _isInitialLoading = false;
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to refresh quotes: $e';
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _refreshVisibleQuotes() async {
    final List<_SymbolInfo> visibleSymbols = _filteredSymbols.take(20).toList(); // Only refresh first 20 visible symbols
    final List<String> symbolsToRefresh = <String>[];
    
    // Check which symbols need refresh based on cache expiry
    for (final symbol in visibleSymbols) {
      final DateTime? lastUpdate = _quoteTimestamps[symbol.finnhubSymbol];
      if (lastUpdate == null || DateTime.now().difference(lastUpdate) > _cacheExpiry) {
        symbolsToRefresh.add(symbol.finnhubSymbol);
      }
    }
    
    if (symbolsToRefresh.isEmpty) return;
    
    print('Refreshing ${symbolsToRefresh.length} quotes that are expired');
    
    // Batch API calls in groups to avoid hitting rate limits
    await _fetchQuotesBatch(symbolsToRefresh);
  }

  Future<void> _fetchQuotesBatch(List<String> symbols) async {
    // Process symbols in batches to control concurrent requests
    for (int i = 0; i < symbols.length; i += _maxConcurrentRequests) {
      final int end = (i + _maxConcurrentRequests).clamp(0, symbols.length);
      final List<String> batch = symbols.sublist(i, end);
      
      final List<Future<_Quote?>> futures = batch.map((symbol) => _fetchQuote(symbol)).toList();
      final List<_Quote?> results = await Future.wait(futures);
      
      for (int j = 0; j < batch.length; j++) {
        final String symbol = batch[j];
        final _Quote? quote = results[j];
        if (quote != null) {
          _quotesBySymbol[symbol] = quote;
          _quoteTimestamps[symbol] = DateTime.now();
        }
      }
      
      // Small delay between batches to be respectful to API
      if (end < symbols.length) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    
    if (mounted) setState(() {});
  }

  Future<void> _loadMoreSymbols() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;
    try {
      // Check cache first
      List<_SymbolInfo> symbols;
      if (_cachedSymbolsByExchange.containsKey(_exchange)) {
        print('Using cached symbols for $_exchange');
        final cached = _cachedSymbolsByExchange[_exchange]!;
        final int start = _page * _pageSize;
        final int end = (start + _pageSize).clamp(0, cached.length);
        
        if (start >= cached.length) {
          symbols = [];
        } else {
          symbols = cached.sublist(start, end);
        }
      } else {
        // Load symbols from Finnhub exchange and cache them
        symbols = await _fetchSymbolsFromExchange(_exchange, _page);
      }
      
      if (symbols.isNotEmpty) {
        setState(() => _dynamicSymbols.addAll(symbols));
        _page++;
        
        // Load quotes for new symbols in optimized batches
        final List<String> symbolsToFetch = symbols.map((s) => s.finnhubSymbol).toList();
        await _fetchQuotesBatch(symbolsToFetch);
      }
    } catch (e) {
      setState(() => _error = 'Failed to load symbols');
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<List<_SymbolInfo>> _fetchSymbolsFromExchange(String exchange, int page) async {
    try {
      // If not cached, fetch all symbols for this exchange at once
      if (!_cachedSymbolsByExchange.containsKey(exchange)) {
        print('Fetching and caching all symbols from exchange: $exchange');
        final uri = Uri.parse(FinnhubConstants.symbolsUrl(exchange));
        final res = await http.get(uri).timeout(const Duration(seconds: 15));
        
        print('Symbols API Status: ${res.statusCode}');
        
        if (res.statusCode == 200) {
          final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
          print('Fetched ${data.length} symbols from $exchange');
          
          final List<_SymbolInfo> allSymbols = <_SymbolInfo>[];
          for (final item in data) {
            final Map<String, dynamic> symbolData = item as Map<String, dynamic>;
            final String symbol = symbolData['symbol'] as String? ?? '';
            final String description = symbolData['description'] as String? ?? symbol;
            
            // Filter for quality symbols
            if (symbol.isNotEmpty && 
                !symbol.contains('.') && 
                symbol.length <= 6 &&
                !symbol.contains('-') &&
                RegExp(r'^[A-Z]+$').hasMatch(symbol)) {
              allSymbols.add(_SymbolInfo(
                symbol: symbol,
                display: symbol,
                subtitle: description,
                finnhubSymbol: symbol,
                isIndex: false,
              ));
            }
          }
          
          // Cache the filtered symbols
          _cachedSymbolsByExchange[exchange] = allSymbols;
          print('Cached ${allSymbols.length} valid symbols for $exchange');
        } else {
          print('Failed to fetch symbols: HTTP ${res.statusCode} - ${res.body}');
          return [];
        }
      }
      
      // Return the requested page from cache
      final cached = _cachedSymbolsByExchange[exchange]!;
      final int start = page * _pageSize;
      final int end = (start + _pageSize).clamp(0, cached.length);
      
      if (start >= cached.length) return [];
      
      return cached.sublist(start, end);
      
    } catch (e) {
      print('Error fetching symbols from $exchange: $e');
      return [];
    }
  }

  Future<_Quote?> _fetchQuote(String symbol) async {
    try {
      // Check cache first
      final cachedTimestamp = _quoteTimestamps[symbol];
      final cachedQuote = _quotesBySymbol[symbol];
      
      if (cachedTimestamp != null && 
          cachedQuote != null &&
          DateTime.now().difference(cachedTimestamp) < _cacheExpiry) {
        print('Using cached quote for $symbol');
        return cachedQuote;
      }
      
      print('Fetching fresh quote for symbol: $symbol');
      final uri = Uri.parse(FinnhubConstants.quoteUrl(symbol));
      
      final res = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Timeout fetching quote for $symbol');
          throw TimeoutException('Request timeout for $symbol', const Duration(seconds: 10));
        },
      );
      
      print('HTTP Status for $symbol: ${res.statusCode}');
      
      if (res.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(res.body) as Map<String, dynamic>;
            
        print('API Response for $symbol: $body');
        
        // Check if the response contains valid data
        if (body.isEmpty || body['c'] == null) {
          print('Empty or invalid response for $symbol');
          return null;
        }
        
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
        
        // Cache the quote
        _quotesBySymbol[symbol] = quote;
        _quoteTimestamps[symbol] = DateTime.now();
        
        print('Successfully fetched quote for $symbol: price=$current, change=$change');
        return quote;
      } else {
        print('Failed to fetch quote for $symbol: HTTP ${res.statusCode} - ${res.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching quote for $symbol: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
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
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      TextButton(
                        onPressed: _refreshAll,
                        child: const Text('Retry', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              if (_isInitialLoading)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading stock data...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!_isInitialLoading)
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshAll,
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
                          return SimpleCard(child: _buildQuoteTile(info, quote));
                        },
                      ),
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
    final String dateLabel =
        '${months[now.month - 1]} ${now.day}, ${now.year}';

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
        if (_lastUpdated != null) ...[
          const SizedBox(height: 4),
          Text(
            'Last updated: ${_lastUpdated!.hour.toString().padLeft(2, '0')}:${_lastUpdated!.minute.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
                final String exchange = _exchanges[index];
                final bool selected = exchange == _exchange;
                return FilterChip(
                  showCheckmark: false,
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _exchange = exchange;
                      _page = 0;
                      _dynamicSymbols.clear();
                      _quotesBySymbol.clear();
                    });
                    _loadMoreSymbols();
                  },
                  label: Text(exchange),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.primary,
                  ),
                  backgroundColor: Colors.transparent,
                  selectedColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                );
              },
            ),
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

  Widget _buildTopMovers() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          '📈 Top Movers\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteTile(_SymbolInfo info, _Quote? quote) {
    final bool hasQuote = quote != null;
    final double price = hasQuote ? quote.price : 0.0;
    final double change = hasQuote ? (quote.extra?.change ?? 0.0) : 0.0;
    final double changePercent = hasQuote ? (quote.extra?.changePercent ?? 0.0) : 0.0;
    final bool isUp = change > 0;
    final bool isDown = change < 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: info.isIndex ? AppColors.accent : AppColors.primary,
        child: Text(
          info.isIndex ? '📊' : info.symbol.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        info.display,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        info.subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: hasQuote
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isUp
                        ? Colors.green.withOpacity(0.1)
                        : isDown
                            ? Colors.red.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${isUp ? '+' : ''}${change.toStringAsFixed(2)} (${changePercent.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      color: isUp
                          ? Colors.green
                          : isDown
                              ? Colors.red
                              : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )
          : const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
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
    int? volume,
  }) {
    this.price = price;
    this.timestampMs = timestampMs;
    if (volume != null) this.volume = volume;
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

  final String symbol;
  final String display;
  final String subtitle;
  final String finnhubSymbol;
  final bool isIndex;
}

// Simple glass card effect widget
class SimpleCard extends StatelessWidget {
  const SimpleCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
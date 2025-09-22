// crypto_exchange_rates_page.dart
import 'package:flutter/material.dart';
import '../theme.dart';
import '/services/crypto_api_service.dart';

class CryptoExchangeRatesPage extends StatefulWidget {
  const CryptoExchangeRatesPage({super.key});

  @override
  State<CryptoExchangeRatesPage> createState() =>
      _CryptoExchangeRatesPageState();
}

class _CryptoExchangeRatesPageState extends State<CryptoExchangeRatesPage> {
  Map<String, double>? exchangeRates;
  bool isLoading = true;
  String? errorMessage;
  String selectedBaseCurrency = 'USD';

  final List<String> currencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CAD',
    'AUD',
    'CHF',
    'CNY',
    'INR',
  ];

  final List<String> cryptocurrencies = [
    'BTC',
    'ETH',
    'XRP',
    'LTC',
    'BCH',
    'ADA',
    'DOT',
    'LINK',
    'UNI',
    'DOGE',
  ];

  @override
  void initState() {
    super.initState();
    fetchExchangeRates();
  }

  Future<void> fetchExchangeRates() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final rates = await CryptoApiService.getLiveRates(
        symbols: cryptocurrencies,
        target: selectedBaseCurrency,
      );

      setState(() {
        exchangeRates = rates;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: TouchEffectOverlay(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'Crypto Exchange Rates',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.primary,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: fetchExchangeRates,
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Base Currency Selector
                  Container(
                    constraints: BoxConstraints(minHeight: 80),
                    child: Glass3DCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Base Currency',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: selectedBaseCurrency,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: currencies.map((String currency) {
                                return DropdownMenuItem<String>(
                                  value: currency,
                                  child: Text(currency),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    selectedBaseCurrency = newValue;
                                  });
                                  fetchExchangeRates();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Exchange Rates Content
                  Expanded(
                    child: isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading exchange rates...',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          )
                        : errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(color: Colors.red),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: fetchExchangeRates,
                                  icon: Icon(Icons.refresh),
                                  label: Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : exchangeRates == null
                        ? Center(
                            child: Text(
                              'No data available',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: fetchExchangeRates,
                            child: ListView.builder(
                              itemCount: cryptocurrencies.length,
                              itemBuilder: (context, index) {
                                final crypto = cryptocurrencies[index];
                                final rate = exchangeRates![crypto];

                                if (rate == null) {
                                  return const SizedBox.shrink();
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Glass3DCard(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        child: Text(
                                          crypto,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        crypto,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      subtitle: Text(
                                        '1 $crypto = ${rate.toStringAsFixed(2)} $selectedBaseCurrency',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            rate.toStringAsFixed(2),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                          ),
                                          Text(
                                            selectedBaseCurrency,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

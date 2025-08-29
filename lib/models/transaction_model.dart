/// Model representing a blockchain transaction
class TransactionModel {
  final String hash;
  final String from;
  final String to;
  final double amount;
  final String currency;
  final DateTime timestamp;
  final int confirmations;
  final double gasUsed;
  final double gasPrice;
  final TransactionStatus status;
  final String? memo;
  final String network;
  
  const TransactionModel({
    required this.hash,
    required this.from,
    required this.to,
    required this.amount,
    required this.currency,
    required this.timestamp,
    required this.confirmations,
    required this.gasUsed,
    required this.gasPrice,
    required this.status,
    this.memo,
    required this.network,
  });
  
  /// Creates a TransactionModel from blockchain data
  factory TransactionModel.fromBlockchain({
    required String hash,
    required String from,
    required String to,
    required double amount,
    required String currency,
    required DateTime timestamp,
    required int confirmations,
    required double gasUsed,
    required double gasPrice,
    required TransactionStatus status,
    String? memo,
    required String network,
  }) {
    return TransactionModel(
      hash: hash,
      from: from,
      to: to,
      amount: amount,
      currency: currency,
      timestamp: timestamp,
      confirmations: confirmations,
      gasUsed: gasUsed,
      gasPrice: gasPrice,
      status: status,
      memo: memo,
      network: network,
    );
  }
  
  /// Creates a TransactionModel from JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      hash: json['hash'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      confirmations: json['confirmations'] as int,
      gasUsed: (json['gasUsed'] as num).toDouble(),
      gasPrice: (json['gasPrice'] as num).toDouble(),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      memo: json['memo'] as String?,
      network: json['network'] as String,
    );
  }
  
  /// Converts TransactionModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'hash': hash,
      'from': from,
      'to': to,
      'amount': amount,
      'currency': currency,
      'timestamp': timestamp.toIso8601String(),
      'confirmations': confirmations,
      'gasUsed': gasUsed,
      'gasPrice': gasPrice,
      'status': status.name,
      'memo': memo,
      'network': network,
    };
  }
  
  /// Returns transaction fee in the network's currency
  double get transactionFee => gasUsed * gasPrice;
  
  /// Returns if the transaction is confirmed (usually 12+ confirmations)
  bool get isConfirmed => confirmations >= 12;
  
  /// Returns if the transaction is pending
  bool get isPending => status == TransactionStatus.pending;
  
  /// Returns if the transaction failed
  bool get isFailed => status == TransactionStatus.failed;
  
  /// Returns a shortened version of the hash for display
  String get shortHash => '${hash.substring(0, 6)}...${hash.substring(hash.length - 4)}';
  
  /// Returns a shortened version of addresses for display
  String get shortFrom => '${from.substring(0, 6)}...${from.substring(from.length - 4)}';
  String get shortTo => '${to.substring(0, 6)}...${to.substring(to.length - 4)}';
  
  @override
  String toString() {
    return 'TransactionModel(hash: $shortHash, from: $shortFrom, to: $shortTo, amount: $amount $currency, status: ${status.name})';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel && other.hash == hash;
  }
  
  @override
  int get hashCode => hash.hashCode;
}

/// Transaction status enumeration
enum TransactionStatus {
  pending,
  confirmed,
  failed,
  dropped,
}

/// Extension to get user-friendly status names
extension TransactionStatusExtension on TransactionStatus {
  String get displayName {
    switch (this) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.confirmed:
        return 'Confirmed';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.dropped:
        return 'Dropped';
    }
  }
  
  /// Returns appropriate color for the status
  String get colorHex {
    switch (this) {
      case TransactionStatus.pending:
        return '#FFA500'; // Orange
      case TransactionStatus.confirmed:
        return '#00FF00'; // Green
      case TransactionStatus.failed:
        return '#FF0000'; // Red
      case TransactionStatus.dropped:
        return '#808080'; // Gray
    }
  }
}

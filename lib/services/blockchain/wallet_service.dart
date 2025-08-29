import 'dart:typed_data';
import 'dart:math';
import 'package:web3dart/web3dart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:hex/hex.dart';

/// Service responsible for wallet creation, management, and key operations
class WalletService {
  static const _storage = FlutterSecureStorage();
  
  // Storage keys
  static const String _mnemonicKey = 'ledgerly_mnemonic';
  static const String _privateKeyKey = 'ledgerly_private_key';
  static const String _walletAddressKey = 'ledgerly_wallet_address';
  
  /// Generates a new wallet with mnemonic phrase
  /// Returns the mnemonic phrase that should be securely stored by the user
  static Future<String> generateWallet() async {
    // Generate 12-word mnemonic
    final mnemonic = bip39.generateMnemonic(strength: 128);
    
    // Derive private key from mnemonic
    final seed = bip39.mnemonicToSeed(mnemonic);
    final master = await ED25519_HD_KEY.getMasterKeyFromSeed(seed);
    final privateKey = HEX.encode(master.key);
    
    // Create wallet credentials
    final credentials = EthPrivateKey.fromHex(privateKey);
    final address = await credentials.extractAddress();
    
    // Store securely
    await _storage.write(key: _mnemonicKey, value: mnemonic);
    await _storage.write(key: _privateKeyKey, value: privateKey);
    await _storage.write(key: _walletAddressKey, value: address.hex);
    
    return mnemonic;
  }
  
  /// Imports a wallet from an existing mnemonic phrase
  static Future<bool> importWallet(String mnemonic) async {
    try {
      // Validate mnemonic
      if (!bip39.validateMnemonic(mnemonic)) {
        return false;
      }
      
      // Derive private key from mnemonic
      final seed = bip39.mnemonicToSeed(mnemonic);
      final master = await ED25519_HD_KEY.getMasterKeyFromSeed(seed);
      final privateKey = HEX.encode(master.key);
      
      // Create wallet credentials
      final credentials = EthPrivateKey.fromHex(privateKey);
      final address = await credentials.extractAddress();
      
      // Store securely
      await _storage.write(key: _mnemonicKey, value: mnemonic);
      await _storage.write(key: _privateKeyKey, value: privateKey);
      await _storage.write(key: _walletAddressKey, value: address.hex);
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Gets the wallet credentials for transactions
  static Future<EthPrivateKey?> getCredentials() async {
    try {
      final privateKey = await _storage.read(key: _privateKeyKey);
      if (privateKey == null) return null;
      
      return EthPrivateKey.fromHex(privateKey);
    } catch (e) {
      return null;
    }
  }
  
  /// Gets the wallet address
  static Future<String?> getWalletAddress() async {
    return await _storage.read(key: _walletAddressKey);
  }
  
  /// Gets the mnemonic phrase (for backup purposes)
  static Future<String?> getMnemonic() async {
    return await _storage.read(key: _mnemonicKey);
  }
  
  /// Checks if a wallet exists
  static Future<bool> hasWallet() async {
    final privateKey = await _storage.read(key: _privateKeyKey);
    return privateKey != null;
  }
  
  /// Deletes the wallet (use with extreme caution)
  static Future<void> deleteWallet() async {
    await _storage.delete(key: _mnemonicKey);
    await _storage.delete(key: _privateKeyKey);
    await _storage.delete(key: _walletAddressKey);
  }
  
  /// Validates an Ethereum address
  static bool isValidAddress(String address) {
    try {
      EthereumAddress.fromHex(address);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Generates a random private key (for testing purposes only)
  static String generateRandomPrivateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return HEX.encode(bytes);
  }
}

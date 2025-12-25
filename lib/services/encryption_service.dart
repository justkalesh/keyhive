import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// EncryptionService - Manages the secure encryption key for Hive database.
/// 
/// SECURITY ARCHITECTURE:
/// 1. On FIRST LAUNCH: A cryptographically secure 32-byte AES key is generated.
/// 2. This key is stored in FlutterSecureStorage (Android Keystore / iOS Keychain).
/// 3. On SUBSEQUENT LAUNCHES: The key is retrieved from secure storage.
/// 4. The Hive box is opened ONLY with this key using HiveAesCipher.
/// 
/// CRITICAL: The encryption key NEVER leaves the secure storage.
/// All Hive data is AES-256 encrypted at rest.
class EncryptionService {
  static const String _keyStorageKey = 'keyhive_encryption_key';
  
  final FlutterSecureStorage _secureStorage;
  
  EncryptionService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
        );

  /// Generates a cryptographically secure 32-byte (256-bit) AES key.
  /// Uses Hive's built-in secure random generator.
  Uint8List generateEncryptionKey() {
    return Uint8List.fromList(Hive.generateSecureKey());
  }

  /// Stores the encryption key in FlutterSecureStorage.
  /// The key is stored as a comma-separated string of bytes.
  Future<void> storeKey(Uint8List key) async {
    final keyString = key.join(',');
    await _secureStorage.write(key: _keyStorageKey, value: keyString);
  }

  /// Retrieves the encryption key from FlutterSecureStorage.
  /// Returns null if no key exists (first launch).
  Future<Uint8List?> getKey() async {
    final keyString = await _secureStorage.read(key: _keyStorageKey);
    if (keyString == null) return null;
    
    final keyBytes = keyString.split(',').map((s) => int.parse(s)).toList();
    return Uint8List.fromList(keyBytes);
  }

  /// Checks if an encryption key has been generated and stored.
  /// Returns true if the app has been initialized before.
  Future<bool> hasKey() async {
    final key = await _secureStorage.read(key: _keyStorageKey);
    return key != null;
  }

  /// Initializes the encryption key.
  /// - If a key exists, retrieves it.
  /// - If no key exists (first launch), generates and stores a new one.
  /// Returns the encryption key for opening the Hive box.
  Future<Uint8List> initializeKey() async {
    final existingKey = await getKey();
    
    if (existingKey != null) {
      return existingKey;
    }
    
    // First launch: Generate a new secure key
    final newKey = generateEncryptionKey();
    await storeKey(newKey);
    return newKey;
  }
}

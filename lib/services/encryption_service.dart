import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:encrypt/encrypt.dart' as enc;

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
  
  /// Cached encryption key for encrypt/decrypt operations
  enc.Key? _cachedKey;
  
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
      // Cache the key for encrypt/decrypt operations
      _cachedKey = enc.Key(existingKey);
      return existingKey;
    }
    
    // First launch: Generate a new secure key
    final newKey = generateEncryptionKey();
    await storeKey(newKey);
    
    // Cache the key for encrypt/decrypt operations
    _cachedKey = enc.Key(newKey);
    return newKey;
  }

  /// Encrypts a string using AES-256-CBC with a random IV.
  /// Returns format: 'iv_base64:ciphertext_base64'
  String encryptString(String plainText) {
    if (_cachedKey == null) {
      throw StateError('Encryption key not initialized. Call initializeKey() first.');
    }
    
    // Generate a random IV for each encryption (16 bytes for AES)
    final iv = enc.IV.fromSecureRandom(16);
    
    // Create AES encrypter with CBC mode
    final encrypter = enc.Encrypter(enc.AES(_cachedKey!, mode: enc.AESMode.cbc));
    
    // Encrypt the plaintext
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    
    // Return in format: iv_base64:ciphertext_base64
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts a string encrypted with encryptString.
  /// Input format: 'iv_base64:ciphertext_base64'
  /// Returns null if decryption fails.
  String? decryptString(String encryptedText) {
    if (_cachedKey == null) {
      return null;
    }
    
    try {
      // Split the input to get IV and ciphertext
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        return null;
      }
      
      final ivBase64 = parts[0];
      final ciphertextBase64 = parts[1];
      
      // Decode IV and ciphertext
      final iv = enc.IV.fromBase64(ivBase64);
      final encrypted = enc.Encrypted.fromBase64(ciphertextBase64);
      
      // Create AES decrypter with CBC mode
      final encrypter = enc.Encrypter(enc.AES(_cachedKey!, mode: enc.AESMode.cbc));
      
      // Decrypt and return
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      return null;
    }
  }
}

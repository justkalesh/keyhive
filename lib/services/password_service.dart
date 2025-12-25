import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/password_entry.dart';

/// PasswordService - CRUD operations for password entries.
/// 
/// SECURITY: This service operates on an AES-256 encrypted Hive box.
/// The box is only opened after successful biometric authentication.
/// 
/// IMPORTANT: The `initialize()` method MUST be called with the encryption
/// key before any other operations. This ensures the box is never opened
/// without proper authentication.
class PasswordService {
  static const String _boxName = 'passwords';
  
  Box<PasswordEntry>? _box;
  final Uuid _uuid = const Uuid();

  /// Whether the service has been initialized with an encryption key.
  bool get isInitialized => _box != null && _box!.isOpen;

  /// Initializes the encrypted Hive box.
  /// 
  /// SECURITY: This method requires the encryption key retrieved from
  /// FlutterSecureStorage. The box is opened with HiveAesCipher.
  /// 
  /// [encryptionKey] - 32-byte AES encryption key
  Future<void> initialize(Uint8List encryptionKey) async {
    if (_box != null && _box!.isOpen) {
      return; // Already initialized
    }

    // Open the box with AES encryption
    _box = await Hive.openBox<PasswordEntry>(
      _boxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  /// Closes the encrypted box.
  /// Should be called when the app goes to background or user logs out.
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }

  /// Adds a new password entry.
  /// Returns the created entry with generated ID.
  Future<PasswordEntry> addPassword({
    required String platformName,
    required String username,
    required String password,
  }) async {
    _ensureInitialized();

    final now = DateTime.now();
    final entry = PasswordEntry(
      id: _uuid.v4(),
      platformName: platformName,
      username: username,
      password: password,
      dateCreated: now,
      dateModified: now,
    );

    await _box!.put(entry.id, entry);
    return entry;
  }

  /// Updates an existing password entry.
  Future<void> updatePassword(PasswordEntry entry) async {
    _ensureInitialized();
    
    final updatedEntry = PasswordEntry(
      id: entry.id,
      platformName: entry.platformName,
      username: entry.username,
      password: entry.password,
      dateCreated: entry.dateCreated,
      dateModified: DateTime.now(),
    );
    
    await _box!.put(entry.id, updatedEntry);
  }

  /// Deletes a password entry by ID.
  Future<void> deletePassword(String id) async {
    _ensureInitialized();
    await _box!.delete(id);
  }

  /// Retrieves all password entries, sorted by platform name.
  List<PasswordEntry> getAllPasswords() {
    _ensureInitialized();
    final passwords = _box!.values.toList();
    passwords.sort((a, b) => 
        a.platformName.toLowerCase().compareTo(b.platformName.toLowerCase()));
    return passwords;
  }

  /// Retrieves a single password entry by ID.
  PasswordEntry? getPasswordById(String id) {
    _ensureInitialized();
    return _box!.get(id);
  }

  /// Searches password entries by platform name or username.
  /// Returns entries that contain the query (case-insensitive).
  List<PasswordEntry> searchPasswords(String query) {
    _ensureInitialized();
    
    if (query.isEmpty) {
      return getAllPasswords();
    }

    final lowerQuery = query.toLowerCase();
    final passwords = _box!.values.where((entry) =>
        entry.platformName.toLowerCase().contains(lowerQuery) ||
        entry.username.toLowerCase().contains(lowerQuery)).toList();
    
    passwords.sort((a, b) =>
        a.platformName.toLowerCase().compareTo(b.platformName.toLowerCase()));
    
    return passwords;
  }

  /// Ensures the box is initialized before operations.
  void _ensureInitialized() {
    if (_box == null || !_box!.isOpen) {
      throw StateError(
        'PasswordService not initialized. Call initialize() with encryption key first.',
      );
    }
  }
}

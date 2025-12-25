import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/password_entry.dart';
import '../services/encryption_service.dart';
import '../services/auth_service.dart';
import '../services/password_service.dart';

/// Riverpod Providers for KeyHive Password Manager
/// 
/// ARCHITECTURE:
/// - Services are singletons (created once, reused)
/// - State is reactive (UI updates automatically on changes)
/// - Authentication state controls access to password data

// =============================================================================
// SERVICE PROVIDERS
// =============================================================================

/// Singleton EncryptionService provider
final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService();
});

/// Singleton AuthService provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Singleton PasswordService provider
final passwordServiceProvider = Provider<PasswordService>((ref) {
  return PasswordService();
});

// =============================================================================
// AUTHENTICATION STATE
// =============================================================================

/// Authentication state - tracks whether user is authenticated
final isAuthenticatedProvider = StateProvider<bool>((ref) => false);

/// Encryption key - stored after successful authentication
final encryptionKeyProvider = StateProvider<Uint8List?>((ref) => null);

// =============================================================================
// PASSWORD LIST STATE
// =============================================================================

/// Search query state
final searchQueryProvider = StateProvider<String>((ref) => '');

// =============================================================================
// THEME STATE
// =============================================================================

/// Theme mode state - true = dark mode, false = light mode
final isDarkModeProvider = StateProvider<bool>((ref) => true);

/// All passwords from the database (reactive)
/// This provider is invalidated when passwords are added/updated/deleted
final passwordListProvider = StateNotifierProvider<PasswordListNotifier, List<PasswordEntry>>((ref) {
  final passwordService = ref.watch(passwordServiceProvider);
  return PasswordListNotifier(passwordService);
});

/// Filtered passwords based on search query
final filteredPasswordsProvider = Provider<List<PasswordEntry>>((ref) {
  final passwords = ref.watch(passwordListProvider);
  final query = ref.watch(searchQueryProvider);
  
  if (query.isEmpty) {
    return passwords;
  }
  
  final lowerQuery = query.toLowerCase();
  return passwords.where((entry) =>
      entry.platformName.toLowerCase().contains(lowerQuery) ||
      entry.username.toLowerCase().contains(lowerQuery)).toList();
});

/// StateNotifier for managing password list
class PasswordListNotifier extends StateNotifier<List<PasswordEntry>> {
  final PasswordService _passwordService;
  
  PasswordListNotifier(this._passwordService) : super([]);

  /// Loads all passwords from the encrypted database
  void loadPasswords() {
    if (!_passwordService.isInitialized) {
      state = [];
      return;
    }
    state = _passwordService.getAllPasswords();
  }

  /// Adds a new password and updates state
  Future<PasswordEntry> addPassword({
    required String platformName,
    required String username,
    required String password,
  }) async {
    final entry = await _passwordService.addPassword(
      platformName: platformName,
      username: username,
      password: password,
    );
    state = _passwordService.getAllPasswords();
    return entry;
  }

  /// Updates a password and refreshes state
  Future<void> updatePassword(PasswordEntry entry) async {
    await _passwordService.updatePassword(entry);
    state = _passwordService.getAllPasswords();
  }

  /// Deletes a password and refreshes state
  Future<void> deletePassword(String id) async {
    await _passwordService.deletePassword(id);
    state = _passwordService.getAllPasswords();
  }
}

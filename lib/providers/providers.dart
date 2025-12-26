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

// =============================================================================
// SECURITY SETTINGS
// =============================================================================

/// Clipboard auto-clear enabled (default: true)
final clipboardAutoClearProvider = StateProvider<bool>((ref) => true);

/// Clipboard auto-clear duration in seconds (default: 30)
final clipboardClearDurationProvider = StateProvider<int>((ref) => 30);

/// Lock app when minimized/backgrounded (default: true)
final lockOnMinimizeProvider = StateProvider<bool>((ref) => true);

/// Password visibility auto-hide enabled (default: true)
final passwordAutoHideProvider = StateProvider<bool>((ref) => true);

/// Password visibility duration in seconds (default: 30)
final passwordVisibilityDurationProvider = StateProvider<int>((ref) => 30);

/// Import conflict resolution mode: true = auto (keep recent), false = manual (show dialog)
final importAutoResolveProvider = StateProvider<bool>((ref) => false);

/// Show tutorial on home screen (first time user)
final showTutorialProvider = StateProvider<bool>((ref) => false);

// =============================================================================
// SORT OPTIONS
// =============================================================================

/// Sort option enum
enum SortOption {
  nameAsc,
  nameDesc,
  dateNewest,
  dateOldest,
}

/// Current sort option state
final sortOptionProvider = StateProvider<SortOption>((ref) => SortOption.nameAsc);

/// All passwords from the database (reactive)
/// This provider is invalidated when passwords are added/updated/deleted
final passwordListProvider = StateNotifierProvider<PasswordListNotifier, List<PasswordEntry>>((ref) {
  final passwordService = ref.watch(passwordServiceProvider);
  return PasswordListNotifier(passwordService);
});

/// Filtered and sorted passwords based on search query and sort option
final filteredPasswordsProvider = Provider<List<PasswordEntry>>((ref) {
  final passwords = ref.watch(passwordListProvider);
  final query = ref.watch(searchQueryProvider);
  final sortOption = ref.watch(sortOptionProvider);
  
  // Filter by search query
  List<PasswordEntry> filtered = passwords;
  if (query.isNotEmpty) {
    final lowerQuery = query.toLowerCase();
    filtered = passwords.where((entry) =>
        entry.platformName.toLowerCase().contains(lowerQuery) ||
        entry.username.toLowerCase().contains(lowerQuery)).toList();
  } else {
    // Create a copy so sorting doesn't mutate the original list
    filtered = List<PasswordEntry>.from(passwords);
  }
  
  // Sort based on selected option
  switch (sortOption) {
    case SortOption.nameAsc:
      filtered.sort((a, b) => a.platformName.toLowerCase().compareTo(b.platformName.toLowerCase()));
      break;
    case SortOption.nameDesc:
      filtered.sort((a, b) => b.platformName.toLowerCase().compareTo(a.platformName.toLowerCase()));
      break;
    case SortOption.dateNewest:
      filtered.sort((a, b) => b.dateModified.compareTo(a.dateModified));
      break;
    case SortOption.dateOldest:
      filtered.sort((a, b) => a.dateModified.compareTo(b.dateModified));
      break;
  }
  
  return filtered;
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
    String? websiteUrl,
    String? notes,
    String category = 'General',
    bool isFavorite = false,
  }) async {
    final entry = await _passwordService.addPassword(
      platformName: platformName,
      username: username,
      password: password,
      websiteUrl: websiteUrl,
      notes: notes,
      category: category,
      isFavorite: isFavorite,
    );
    state = _passwordService.getAllPasswords();
    return entry;
  }

  /// Updates a password and refreshes state
  Future<void> updatePassword(PasswordEntry entry) async {
    await _passwordService.updatePassword(entry);
    state = _passwordService.getAllPasswords();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String id) async {
    await _passwordService.toggleFavorite(id);
    state = _passwordService.getAllPasswords();
  }

  /// Deletes a password and refreshes state
  Future<void> deletePassword(String id) async {
    await _passwordService.deletePassword(id);
    state = _passwordService.getAllPasswords();
  }
}

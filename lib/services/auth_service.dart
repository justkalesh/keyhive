import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// AuthService - Handles biometric and device credential authentication.
/// 
/// SECURITY FLOW:
/// 1. App launches -> Lock Screen displayed
/// 2. Biometric prompt triggered automatically
/// 3. User authenticates with fingerprint, face, or device PIN/pattern
/// 4. On SUCCESS: App retrieves encryption key and opens Hive box
/// 5. On FAILURE: User stays on lock screen, no data access
/// 
/// SUPPORTED METHODS:
/// - Fingerprint (Android/iOS)
/// - Face ID (iOS) / Face Recognition (Android)
/// - Device credentials (PIN/Pattern/Password) as fallback
class AuthService {
  final LocalAuthentication _localAuth;
  
  AuthService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  /// Checks if the device supports biometric authentication.
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Returns the list of available biometric types on this device.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Authenticates the user using biometrics or device credentials.
  /// 
  /// Returns true if authentication was successful, false otherwise.
  /// 
  /// SECURITY OPTIONS:
  /// - biometricOnly: false -> Allows PIN/Pattern/Password fallback
  /// - stickyAuth: true -> Auth persists through app lifecycle events
  /// - useErrorDialogs: true -> Shows platform-specific error dialogs
  Future<bool> authenticateUser() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        // Device doesn't support biometrics, but may support device credentials
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your passwords',
        options: const AuthenticationOptions(
          biometricOnly: false, // Allow device credentials (PIN/Pattern)
          stickyAuth: true, // Keep authenticated on app pause/resume
          useErrorDialogs: true, // Show platform error dialogs
        ),
      );
    } on PlatformException catch (e) {
      // Handle specific platform errors
      // Common error codes: NotAvailable, PasscodeNotSet, LockedOut
      print('Authentication error: ${e.code} - ${e.message}');
      return false;
    }
  }

  /// Cancels any ongoing authentication.
  Future<void> cancelAuthentication() async {
    await _localAuth.stopAuthentication();
  }
}

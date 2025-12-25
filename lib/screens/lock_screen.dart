import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

/// LockScreen - Entry point requiring biometric authentication.
/// 
/// SECURITY FLOW:
/// 1. Screen displays immediately on app launch
/// 2. Biometric prompt triggers automatically on build
/// 3. On SUCCESS: 
///    - Retrieves encryption key from secure storage
///    - Initializes encrypted Hive box
///    - Navigates to Home screen
/// 4. On FAILURE:
///    - Shows "Retry" button
///    - No data is loaded or accessible
/// 
/// CRITICAL: The Hive box is NEVER opened before successful authentication.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Trigger authentication after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  /// Initiates the biometric authentication process
  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final encryptionService = ref.read(encryptionServiceProvider);
      final passwordService = ref.read(passwordServiceProvider);

      // Step 1: Authenticate user with biometrics
      final authenticated = await authService.authenticateUser();

      if (!authenticated) {
        setState(() {
          _isAuthenticating = false;
          _errorMessage = 'Authentication failed. Please try again.';
        });
        return;
      }

      // Step 2: Get or generate encryption key
      final encryptionKey = await encryptionService.initializeKey();

      // Step 3: Initialize the encrypted password box
      await passwordService.initialize(encryptionKey);

      // Step 4: Update authentication state
      ref.read(isAuthenticatedProvider.notifier).state = true;
      ref.read(encryptionKeyProvider.notifier).state = encryptionKey;

      // Step 5: Load passwords
      ref.read(passwordListProvider.notifier).loadPasswords();

      // Step 6: Navigate to home screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // App Name
                Text(
                  'KeyHive',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Secure Password Manager',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Status / Error Message
                if (_isAuthenticating) ...[
                  CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Authenticating...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ] else if (_errorMessage != null) ...[
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _authenticate,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Retry Authentication'),
                  ),
                ] else ...[
                  // Initial state - show unlock prompt
                  Icon(
                    Icons.fingerprint,
                    size: 64,
                    color: theme.colorScheme.primary.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Use biometrics to unlock',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _authenticate,
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Unlock'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

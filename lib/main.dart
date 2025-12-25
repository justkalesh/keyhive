import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/password_entry.dart';
import 'providers/providers.dart';
import 'screens/lock_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_edit_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(PasswordEntryAdapter());

  runApp(
    const ProviderScope(
      child: KeyHiveApp(),
    ),
  );
}

/// Main application widget with lifecycle observer for lock on minimize
class KeyHiveApp extends ConsumerStatefulWidget {
  const KeyHiveApp({super.key});

  @override
  ConsumerState<KeyHiveApp> createState() => _KeyHiveAppState();
}

class _KeyHiveAppState extends ConsumerState<KeyHiveApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Lock app when resumed from background (if setting enabled)
    if (state == AppLifecycleState.resumed) {
      final lockOnMinimize = ref.read(lockOnMinimizeProvider);
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      
      if (lockOnMinimize && isAuthenticated) {
        // Reset authentication state and navigate to lock screen
        ref.read(isAuthenticatedProvider.notifier).state = false;
        _navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'KeyHive',
      debugShowCheckedModeBanner: false,
      
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      initialRoute: '/',
      
      routes: {
        '/': (context) => const LockScreen(),
        '/home': (context) => const HomeScreen(),
        '/add': (context) => const AddEditScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      
      onGenerateRoute: (settings) {
        if (settings.name == '/detail') {
          final entryId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => DetailScreen(entryId: entryId),
          );
        }
        if (settings.name == '/edit') {
          final entryId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => AddEditScreen(entryId: entryId),
          );
        }
        return null;
      },
    );
  }
}

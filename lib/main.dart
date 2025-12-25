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
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for Flutter
  await Hive.initFlutter();

  // Register Hive type adapters
  Hive.registerAdapter(PasswordEntryAdapter());

  runApp(
    // Wrap app in ProviderScope for Riverpod
    const ProviderScope(
      child: KeyHiveApp(),
    ),
  );
}

/// Main application widget
class KeyHiveApp extends ConsumerWidget {
  const KeyHiveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    
    return MaterialApp(
      title: 'KeyHive',
      debugShowCheckedModeBanner: false,
      
      // Material 3 Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      // Start with Lock Screen
      initialRoute: '/',
      
      // Route configuration
      routes: {
        '/': (context) => const LockScreen(),
        '/home': (context) => const HomeScreen(),
        '/add': (context) => const AddEditScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      
      // Handle dynamic routes (detail and edit screens require arguments)
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

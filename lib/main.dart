import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Check if user has completed tutorial
  bool hasCompletedTutorial = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    hasCompletedTutorial = prefs.getBool('has_completed_tutorial') ?? false;
  } catch (e) {
    debugPrint('SharedPreferences error: $e');
    hasCompletedTutorial = true; // Skip tutorial on error
  }

  runApp(
    ProviderScope(
      child: KeyHiveApp(showTutorial: !hasCompletedTutorial),
    ),
  );
}

/// Main application widget with lifecycle observer for lock on minimize
class KeyHiveApp extends ConsumerStatefulWidget {
  final bool showTutorial;
  
  const KeyHiveApp({super.key, this.showTutorial = false});

  @override
  ConsumerState<KeyHiveApp> createState() => _KeyHiveAppState();
}

class _KeyHiveAppState extends ConsumerState<KeyHiveApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  DateTime? _pausedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Set tutorial state after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.showTutorial) {
        ref.read(showTutorialProvider.notifier).state = true;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Track when app is paused
    if (state == AppLifecycleState.paused) {
      _pausedTime = DateTime.now();
    }
    
    // Lock app when resumed from background (if setting enabled)
    // Only lock if paused for more than 5 seconds (to avoid share dialogs triggering lock)
    if (state == AppLifecycleState.resumed) {
      final lockOnMinimize = ref.read(lockOnMinimizeProvider);
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      
      final pausedDuration = _pausedTime != null 
          ? DateTime.now().difference(_pausedTime!).inSeconds 
          : 0;
      
      if (lockOnMinimize && isAuthenticated && pausedDuration >= 5) {
        // Reset authentication state and navigate to lock screen
        ref.read(isAuthenticatedProvider.notifier).state = false;
        _navigatorKey.currentState?.pushNamedAndRemoveUntil('/lock', (route) => false);
      }
      
      _pausedTime = null;
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
      
      initialRoute: '/lock',
      
      routes: {
        '/lock': (context) => const LockScreen(),
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

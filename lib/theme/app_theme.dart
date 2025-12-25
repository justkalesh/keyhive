import 'package:flutter/material.dart';

/// AppTheme - Futuristic Design with Logo Color Palette
/// 
/// Design Philosophy:
/// - Navy Blue (#1E3A5F) + Gold (#D4A84B) from logo
/// - Dark mode first with metallic gold accents
/// - Glassmorphism effects
/// - Modern rounded corners
class AppTheme {
  AppTheme._();

  // ==========================================================================
  // COLOR PALETTE - From KeyHive Logo
  // ==========================================================================
  
  // Primary: Navy Blue (from logo border)
  static const Color _navyBlue = Color(0xFF1E3A5F);
  static const Color _navyLight = Color(0xFF2D5A8A);
  
  // Secondary: Gold (from logo honeycomb)
  static const Color _gold = Color(0xFFD4A84B);
  static const Color _goldLight = Color(0xFFE8C675);
  
  // Accent: Teal (from logo accents)
  static const Color _teal = Color(0xFF2A7B9B);
  
  // Background: Deep Space Navy
  static const Color _backgroundDark = Color(0xFF0A0F1A);
  static const Color _surfaceDark = Color(0xFF121A2A);
  static const Color _cardDark = Color(0xFF1A2438);
  
  // Light mode backgrounds
  static const Color _backgroundLight = Color(0xFFF8FAFC);
  static const Color _surfaceLight = Colors.white;
  
  static const Color _errorColor = Color(0xFFF43F5E);
  static const Color _successColor = Color(0xFF10B981);

  // ==========================================================================
  // LIGHT THEME
  // ==========================================================================
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      colorScheme: ColorScheme.light(
        primary: _navyBlue,
        secondary: _gold,
        tertiary: _teal,
        surface: _surfaceLight,
        error: _errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.black87,
        onSurface: Colors.black87,
      ),
      
      scaffoldBackgroundColor: _backgroundLight,
      
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _surfaceLight.withValues(alpha: 0.9),
        foregroundColor: _navyBlue,
        titleTextStyle: const TextStyle(
          color: _navyBlue,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: _surfaceLight,
      ),
      
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _gold,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _navyBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _navyBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _navyBlue,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // DARK THEME - Navy + Gold
  // ==========================================================================
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      colorScheme: ColorScheme.dark(
        primary: _goldLight,
        secondary: _navyLight,
        tertiary: _teal,
        surface: _surfaceDark,
        error: _errorColor,
        onPrimary: _backgroundDark,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      
      scaffoldBackgroundColor: _backgroundDark,
      
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _surfaceDark.withValues(alpha: 0.9),
        foregroundColor: _goldLight,
        titleTextStyle: const TextStyle(
          color: _goldLight,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: _gold.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        color: _cardDark,
      ),
      
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _goldLight,
        foregroundColor: _backgroundDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _gold.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _gold.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _goldLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _goldLight,
          foregroundColor: _backgroundDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _goldLight,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _goldLight;
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _goldLight.withValues(alpha: 0.3);
          }
          return Colors.grey.withValues(alpha: 0.3);
        }),
      ),
      
      popupMenuTheme: PopupMenuThemeData(
        color: _cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _gold.withValues(alpha: 0.2),
          ),
        ),
      ),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _cardDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      dialogTheme: DialogThemeData(
        backgroundColor: _surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
  
  // ==========================================================================
  // GRADIENT HELPERS - Logo Colors
  // ==========================================================================
  
  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [_navyBlue, _teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get goldGradient => const LinearGradient(
    colors: [_gold, _goldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get neonGradient => const LinearGradient(
    colors: [_gold, _navyLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get logoGradient => const LinearGradient(
    colors: [_navyBlue, _gold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors - Desert Gold Theme
  static const Color primaryColor = Color(0xFFD4AF37); // ذهبي دافئ
  static const Color primaryDarkColor = Color(0xFFB8941F); // ذهبي داكن
  static const Color accentColor = Color(0xFF2C3E50); // أزرق داكن
  static const Color backgroundColor = Color(0xFFF8F9FA); // رمادي فاتح جداً
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFF44336);
  static const Color textPrimaryColor = Color(0xFF1A1A1A); // أسود دافئ
  static const Color textSecondaryColor = Color(0xFF6C757D); // رمادي متوسط
  
  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primaryDarkColor],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        onPrimary: surfaceColor,
        primaryContainer: primaryDarkColor,
        onPrimaryContainer: surfaceColor,
        secondary: accentColor,
        onSecondary: surfaceColor,
        error: errorColor,
        onError: surfaceColor,
        surface: surfaceColor,
        onSurface: textPrimaryColor,
        surfaceContainerHighest: backgroundColor,
      ),
      textTheme: GoogleFonts.notoSansArabicTextTheme(
        ThemeData.light().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: surfaceColor,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
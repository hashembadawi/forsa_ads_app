import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// مدير الثيم المحسن للأداء مع خط Inter فقط
class AppThemeManager {
  
  // الألوان الأساسية للتطبيق
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryOrange = Color(0xFFFF9800);
  static const Color primaryPurple = Color(0xFF9C27B0);
  
  // ثيم فاتح محسن للغة العربية
  static ThemeData getLightTheme({
    Color? primaryColor,
    double fontScale = 1.0,
  }) {
    final primary = primaryColor ?? primaryBlue;
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // نظام الألوان
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      
      // خط Tajawal المحسن للعربية - مصمم خصيصاً للنصوص العربية
      textTheme: GoogleFonts.tajawalTextTheme(
        _buildTextTheme(fontScale, false),
      ),
      
      // شريط التطبيق
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      
      // الأزرار
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // البطاقات
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // حقول الإدخال
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      
      // صفحات التمرير
      scrollbarTheme: const ScrollbarThemeData(
        thumbVisibility: WidgetStatePropertyAll(true),
        thickness: WidgetStatePropertyAll(6),
        radius: Radius.circular(3),
      ),
    );
  }
  
  // ثيم مظلم محسن للغة العربية
  static ThemeData getDarkTheme({
    Color? primaryColor,
    double fontScale = 1.0,
  }) {
    final primary = primaryColor ?? primaryBlue;
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // نظام الألوان
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
      ),
      
      // خط Tajawal المحسن للعربية - مصمم خصيصاً للنصوص العربية  
      textTheme: GoogleFonts.tajawalTextTheme(
        _buildTextTheme(fontScale, true),
      ),
      
      // شريط التطبيق
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      
      // الأزرار
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // البطاقات
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // حقول الإدخال
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      
      // صفحات التمرير
      scrollbarTheme: const ScrollbarThemeData(
        thumbVisibility: WidgetStatePropertyAll(true),
        thickness: WidgetStatePropertyAll(6),
        radius: Radius.circular(3),
      ),
    );
  }
  
  static TextTheme _buildTextTheme(double fontScale, bool isDark) {
    final baseColor = isDark ? Colors.white : Colors.black87;
    
    return TextTheme(
      // العناوين الرئيسية
      displayLarge: TextStyle(
        fontSize: 57 * fontScale,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 45 * fontScale,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontSize: 36 * fontScale,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.3,
      ),
      
      // العناوين الفرعية
      headlineLarge: TextStyle(
        fontSize: 32 * fontScale,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontSize: 28 * fontScale,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 24 * fontScale,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),
      
      // العناوين الصغيرة
      titleLarge: TextStyle(
        fontSize: 22 * fontScale,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: 18 * fontScale,
        fontWeight: FontWeight.w500,
        color: baseColor,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontSize: 16 * fontScale,
        fontWeight: FontWeight.w500,
        color: baseColor,
        height: 1.4,
      ),
      
      // النصوص العادية
      bodyLarge: TextStyle(
        fontSize: 16 * fontScale,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14 * fontScale,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12 * fontScale,
        fontWeight: FontWeight.w400,
        color: baseColor.withValues(alpha: 0.7),
        height: 1.5,
      ),
      
      // التسميات
      labelLarge: TextStyle(
        fontSize: 14 * fontScale,
        fontWeight: FontWeight.w500,
        color: baseColor,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontSize: 12 * fontScale,
        fontWeight: FontWeight.w500,
        color: baseColor,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontSize: 11 * fontScale,
        fontWeight: FontWeight.w500,
        color: baseColor.withValues(alpha: 0.7),
        height: 1.4,
      ),
    );
  }
  
  /// الألوان المتاحة للاختيار
  static List<Color> get availableColors => [
    primaryBlue,
    primaryGreen,
    primaryOrange,
    primaryPurple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
  ];
  
  /// أحجام الخط المتاحة - مبسطة للأداء
  static List<double> get availableFontScales => [
    0.9,   // صغير
    1.0,   // عادي
    1.1,   // متوسط
    1.2,   // كبير
  ];
  
  /// أسماء أحجام الخط
  static List<String> get fontScaleNames => [
    'صغير',
    'عادي', 
    'متوسط',
    'كبير',
  ];
}

/// أوضاع الثيم المتاحة
enum AppThemeMode {
  light('فاتح', ThemeMode.light),
  dark('مظلم', ThemeMode.dark),
  system('تلقائي', ThemeMode.system);
  
  const AppThemeMode(this.name, this.themeMode);
  
  final String name;
  final ThemeMode themeMode;
}
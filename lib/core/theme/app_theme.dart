import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors - نظام الألوان المناسب للسوق السوري
  static const Color primaryColor = Color(0xFF2196F3); // أزرق سماوي - موثوقية واحتراف
  static const Color primaryDarkColor = Color(0xFF1976D2); // أزرق متوسط داكن
  static const Color accentColor = Color(0xFFFF9800); // برتقالي دافئ - حيوية
  static const Color backgroundColor = Color(0xFFFAFAFA); // رمادي فاتح جداً
  static const Color surfaceColor = Color(0xFFFFFFFF); // أبيض نقي
  static const Color errorColor = Color(0xFFF44336); // أحمر للأخطاء
  static const Color successColor = Color(0xFF4CAF50); // أخضر للنجاح
  static const Color warningColor = Color(0xFFFFC107); // برتقالي للتحذيرات
  static const Color infoColor = Color(0xFF03A9F4); // أزرق فاتح للمعلومات
  static const Color textPrimaryColor = Color(0xFF212121); // أسود داكن
  static const Color textSecondaryColor = Color(0xFF757575); // رمادي متوسط
  static const Color iconInactiveColor = Color(0xFF9E9E9E); // رمادي فاتح للأيقونات غير النشطة
  static const Color buttonSecondaryColor = Color(0xFFE0E0E0); // رمادي باهت للأزرار الثانوية
  
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
        primary: primaryColor, // أزرق سماوي
        onPrimary: surfaceColor, // أبيض
        primaryContainer: primaryDarkColor, // أزرق داكن
        onPrimaryContainer: surfaceColor,
        secondary: accentColor, // برتقالي
        onSecondary: surfaceColor,
        error: errorColor,
        onError: surfaceColor,
        surface: surfaceColor, // أبيض
        onSurface: textPrimaryColor, // أسود داكن
        surfaceContainerHighest: backgroundColor, // رمادي فاتح جداً
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.notoSansArabicTextTheme(
        ThemeData.light().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor, // خلفية بيضاء
        foregroundColor: textPrimaryColor, // نص أسود داكن
        elevation: 1, // ظل خفيف
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColor), // أيقونات زرقاء
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor, // أزرق
          foregroundColor: surfaceColor, // أبيض
          elevation: 2,
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
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor, // خلفية بيضاء
        selectedItemColor: primaryColor, // أزرق عند التفعيل
        unselectedItemColor: iconInactiveColor, // رمادي فاتح
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
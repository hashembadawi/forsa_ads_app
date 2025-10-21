import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// مساعد لاستخدام خط Tajawal بطريقة مباشرة
class TajawalText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? height;

  const TajawalText(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.height,
  });

  /// عنوان رئيسي كبير
  const TajawalText.headlineLarge(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : fontSize = 28,
       fontWeight = FontWeight.bold,
       height = 1.2;

  /// عنوان متوسط
  const TajawalText.headlineMedium(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : fontSize = 22,
       fontWeight = FontWeight.w600,
       height = 1.3;

  /// عنوان صغير
  const TajawalText.headlineSmall(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : fontSize = 18,
       fontWeight = FontWeight.w600,
       height = 1.4;

  /// نص عادي كبير
  const TajawalText.bodyLarge(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : fontSize = 16,
       fontWeight = FontWeight.normal,
       height = 1.5;

  /// نص عادي متوسط
  const TajawalText.bodyMedium(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : fontSize = 14,
       fontWeight = FontWeight.normal,
       height = 1.5;

  /// نص عادي صغير
  const TajawalText.bodySmall(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : fontSize = 12,
       fontWeight = FontWeight.normal,
       height = 1.5;

  /// تسمية للأزرار والروابط
  const TajawalText.labelLarge(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : fontSize = 14,
       fontWeight = FontWeight.w500,
       height = 1.4;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.tajawal(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Extension لتطبيق خط Tajawal على أي TextStyle
extension TajawalTextStyleExtension on TextStyle {
  /// تطبيق خط Tajawal على هذا TextStyle
  TextStyle get tajawal => GoogleFonts.tajawal(textStyle: this);
  
  /// تطبيق خط Tajawal مع وزن محدد
  TextStyle tajawalWith({
    FontWeight? fontWeight,
    double? fontSize,
    Color? color,
    double? height,
  }) => GoogleFonts.tajawal(
    textStyle: this,
    fontWeight: fontWeight,
    fontSize: fontSize,
    color: color,
    height: height,
  );
}

/// مساعد لإنشاء TextStyle مع Tajawal مباشرة
class TajawalStyles {
  /// عناوين رئيسية
  static TextStyle headlineLarge({Color? color}) => GoogleFonts.tajawal(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: color,
    height: 1.2,
  );

  static TextStyle headlineMedium({Color? color}) => GoogleFonts.tajawal(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: color,
    height: 1.3,
  );

  static TextStyle headlineSmall({Color? color}) => GoogleFonts.tajawal(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: color,
    height: 1.4,
  );

  /// نصوص عادية
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.tajawal(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: color,
    height: 1.5,
  );

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.tajawal(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: color,
    height: 1.5,
  );

  static TextStyle bodySmall({Color? color}) => GoogleFonts.tajawal(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: color,
    height: 1.5,
  );

  /// تسميات
  static TextStyle labelLarge({Color? color}) => GoogleFonts.tajawal(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: color,
    height: 1.4,
  );

  static TextStyle labelMedium({Color? color}) => GoogleFonts.tajawal(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: color,
    height: 1.4,
  );

  static TextStyle labelSmall({Color? color}) => GoogleFonts.tajawal(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: color,
    height: 1.4,
  );
}

/// أمثلة على الاستخدام:
/// 
/// ```dart
/// // استخدام Widget مباشر
/// TajawalText.headlineLarge('مرحباً بك في فرصة')
/// 
/// // استخدام Extension
/// Text('النص', style: Theme.of(context).textTheme.bodyLarge?.tajawal)
/// 
/// // استخدام Helper Classes
/// Text('النص', style: TajawalStyles.bodyLarge(color: Colors.blue))
/// ```
import 'package:flutter/material.dart';

extension AppTextStyles on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  // Headings
  TextStyle? get headlineLarge => textTheme.headlineLarge?.copyWith(
    fontWeight: FontWeight.bold,
    height: 1.2,
  );
  
  TextStyle? get headlineMedium => textTheme.headlineMedium?.copyWith(
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  TextStyle? get titleLarge => textTheme.titleLarge?.copyWith(
    fontWeight: FontWeight.bold,
  );
  
  TextStyle? get titleMedium => textTheme.titleMedium?.copyWith(
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  // Body Text
  TextStyle? get bodyLarge => textTheme.bodyLarge;
  
  TextStyle? get bodyMedium => textTheme.bodyMedium?.copyWith(
    height: 1.5,
  );
  
  TextStyle? get bodySmall => textTheme.bodySmall?.copyWith(
    height: 1.4,
  );
  
  // Labels & Buttons
  TextStyle? get labelLarge => textTheme.labelLarge?.copyWith(
    fontWeight: FontWeight.w600,
  );
}

extension AppColors on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  
  // Primary Colors
  Color get primary => colors.primary;
  Color get onPrimary => colors.onPrimary;
  Color get primaryContainer => colors.primaryContainer;
  
  // Surface Colors
  Color get surface => colors.surface;
  Color get onSurface => colors.onSurface;
  Color get surfaceVariant => colors.surfaceContainerHighest;
  
  // Background (using surface for newer versions)
  Color get background => colors.surface;
  Color get onBackground => colors.onSurface;
  
  // Error
  Color get error => colors.error;
  Color get onError => colors.onError;
  
  // Custom helpers
  Color get textPrimary => onSurface;
  Color get textSecondary => onSurface.withValues(alpha: 0.6);
  Color get divider => onSurface.withValues(alpha: 0.1);
}

extension AppSizes on BuildContext {
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  
  EdgeInsets get padding => MediaQuery.of(this).padding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;
  
  // Responsive breakpoints
  bool get isSmallScreen => screenWidth < 600;
  bool get isMediumScreen => screenWidth >= 600 && screenWidth < 1200;
  bool get isLargeScreen => screenWidth >= 1200;
  
  // Common spacing
  double get spacing4 => 4.0;
  double get spacing8 => 8.0;
  double get spacing12 => 12.0;
  double get spacing16 => 16.0;
  double get spacing20 => 20.0;
  double get spacing24 => 24.0;
  double get spacing32 => 32.0;
}
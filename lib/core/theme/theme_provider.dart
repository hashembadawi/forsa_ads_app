import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme_manager.dart';
import '../utils/logger.dart';

/// حالة إعدادات الثيم
class ThemeSettings {
  final AppThemeMode themeMode;
  final Color primaryColor;
  final double fontScale;

  const ThemeSettings({
    this.themeMode = AppThemeMode.system,
    this.primaryColor = AppThemeManager.primaryGold,
    this.fontScale = 1.0,
  });

  ThemeSettings copyWith({
    AppThemeMode? themeMode,
    Color? primaryColor,
    double? fontScale,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      primaryColor: primaryColor ?? this.primaryColor,
      fontScale: fontScale ?? this.fontScale,
    );
  }

  /// تحويل إلى Map للحفظ
  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode.name,
      'primaryColor': primaryColor.r.toInt() << 16 | primaryColor.g.toInt() << 8 | primaryColor.b.toInt(),
      'fontScale': fontScale,
    };
  }

  /// إنشاء من Map
  factory ThemeSettings.fromMap(Map<String, dynamic> map) {
    return ThemeSettings(
      themeMode: AppThemeMode.values.firstWhere(
        (mode) => mode.name == map['themeMode'],
        orElse: () => AppThemeMode.system,
      ),
      primaryColor: Color(map['primaryColor'] ?? (AppThemeManager.primaryGold.r.toInt() << 16 | AppThemeManager.primaryGold.g.toInt() << 8 | AppThemeManager.primaryGold.b.toInt())),
      fontScale: (map['fontScale'] ?? 1.0).toDouble(),
    );
  }

  @override
  String toString() => 'ThemeSettings(mode: $themeMode, color: $primaryColor, scale: $fontScale)';
}

/// مدير إعدادات الثيم مع التخزين المحلي
class ThemeSettingsNotifier extends StateNotifier<ThemeSettings> {
  static const String _storageKey = 'theme_settings';
  SharedPreferences? _prefs;

  ThemeSettingsNotifier() : super(const ThemeSettings()) {
    _loadSettings();
  }

  /// تحميل الإعدادات من التخزين المحلي
  Future<void> _loadSettings() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final settingsJson = _prefs!.getString(_storageKey);
      
      if (settingsJson != null) {
        // في التطبيق الحقيقي، ستحتاج import 'dart:convert' واستخدام jsonDecode
        // للبساطة، سنحمل الإعدادات الأساسية فقط
        final themeModeName = _prefs!.getString('theme_mode') ?? 'system';
        final primaryColorValue = _prefs!.getInt('primary_color') ?? (AppThemeManager.primaryGold.r.toInt() << 16 | AppThemeManager.primaryGold.g.toInt() << 8 | AppThemeManager.primaryGold.b.toInt());
        final fontScale = _prefs!.getDouble('font_scale') ?? 1.0;

        final themeMode = AppThemeMode.values.firstWhere(
          (mode) => mode.name == themeModeName,
          orElse: () => AppThemeMode.system,
        );

        state = ThemeSettings(
          themeMode: themeMode,
          primaryColor: Color(primaryColorValue),
          fontScale: fontScale,
        );

        logger.info('Theme settings loaded: $state', tag: 'THEME');
      }
    } catch (e) {
      logger.error('Failed to load theme settings', error: e, tag: 'THEME');
    }
  }

  /// حفظ الإعدادات في التخزين المحلي
  Future<void> _saveSettings() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      
      await _prefs!.setString('theme_mode', state.themeMode.name);
      await _prefs!.setInt('primary_color', state.primaryColor.r.toInt() << 16 | state.primaryColor.g.toInt() << 8 | state.primaryColor.b.toInt());
      await _prefs!.setDouble('font_scale', state.fontScale);

      logger.info('Theme settings saved: $state', tag: 'THEME');
    } catch (e) {
      logger.error('Failed to save theme settings', error: e, tag: 'THEME');
    }
  }

  /// تغيير وضع الثيم
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _saveSettings();
    logger.userAction('Theme mode changed', parameters: {'mode': mode.name});
  }

  /// تغيير اللون الأساسي
  Future<void> setPrimaryColor(Color color) async {
    state = state.copyWith(primaryColor: color);
    await _saveSettings();
    logger.userAction('Primary color changed', parameters: {'color': (color.r.toInt() << 16 | color.g.toInt() << 8 | color.b.toInt()).toRadixString(16)});
  }

  /// تغيير حجم الخط
  Future<void> setFontScale(double scale) async {
    if (scale < 0.5 || scale > 2.0) {
      logger.warning('Invalid font scale: $scale. Must be between 0.5 and 2.0', tag: 'THEME');
      return;
    }
    
    state = state.copyWith(fontScale: scale);
    await _saveSettings();
    logger.userAction('Font scale changed', parameters: {'scale': scale});
  }

  /// إعادة تعيين إلى الإعدادات الافتراضية
  Future<void> resetToDefaults() async {
    state = const ThemeSettings();
    await _saveSettings();
    logger.userAction('Theme settings reset to defaults');
  }
}

/// Provider لإعدادات الثيم
final themeSettingsProvider = StateNotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
  (ref) => ThemeSettingsNotifier(),
);

/// Provider للثيم الفاتح
final lightThemeProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  return AppThemeManager.getLightTheme(
    primaryColor: settings.primaryColor,
    fontScale: settings.fontScale,
  );
});

/// Provider للثيم المظلم
final darkThemeProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  return AppThemeManager.getDarkTheme(
    primaryColor: settings.primaryColor,
    fontScale: settings.fontScale,
  );
});

/// Provider لوضع الثيم الحالي
final currentThemeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  return settings.themeMode.themeMode;
});
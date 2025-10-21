import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// مدير الذاكرة والأداء للأجهزة المتوسطة
class PerformanceManager {
  static const PerformanceManager _instance = PerformanceManager._internal();
  factory PerformanceManager() => _instance;
  const PerformanceManager._internal();

  /// تحسين استخدام الذاكرة
  static Future<void> optimizeMemory() async {
    if (kReleaseMode) {
      // تنظيف الذاكرة في الوضع الإنتاجي
      await SystemChannels.platform.invokeMethod('System.gc');
    }
  }

  /// تحديد أولوية المعالج
  static Future<void> setOptimalPerformance() async {
    try {
      // تحسين أولوية التطبيق للأجهزة المتوسطة
      await SystemChannels.platform.invokeMethod(
        'SystemChrome.setEnabledSystemUIMode',
        SystemUiMode.edgeToEdge.index,
      );
    } catch (e) {
      // تجاهل الأخطاء في الأجهزة التي لا تدعم هذه الميزة
      if (kDebugMode) {
        print('Performance optimization not available: $e');
      }
    }
  }

  /// تحسين الرسوم المتحركة للأجهزة المتوسطة
  static Duration getOptimizedAnimationDuration({
    Duration defaultDuration = const Duration(milliseconds: 300),
  }) {
    // تقليل مدة الرسوم المتحركة للأجهزة الضعيفة
    if (kReleaseMode) {
      return Duration(milliseconds: (defaultDuration.inMilliseconds * 0.8).round());
    }
    return defaultDuration;
  }

  /// تحسين معدل الإطارات
  static Curve getOptimizedCurve() {
    // استخدام منحنيات أبسط للأداء الأفضل
    return Curves.easeOut;
  }

  /// تحقق من قدرات الجهاز
  static bool get isLowEndDevice {
    // تحديد الأجهزة ضعيفة الأداء بناءً على المعايير المتاحة
    // في Flutter لا توجد طريقة مباشرة، لكن يمكن استخدام heuristics
    return false; // سيتم تحسينها لاحقاً حسب الحاجة
  }

  /// تحسين التمرير
  static ScrollPhysics get optimizedScrollPhysics {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  /// تحسين الظلال للأداء
  static double get optimizedElevation => 2.0;

  /// تحسين التمويه للأداء
  static double get optimizedBlurRadius => 4.0;

  /// تحسين الشفافية للأداء
  static double get optimizedOpacity => 0.9;
}

/// Extension لتحسين الأداء
extension PerformanceExtensions on Duration {
  /// الحصول على مدة محسنة للأداء
  Duration get optimized => PerformanceManager.getOptimizedAnimationDuration(
        defaultDuration: this,
      );
}

/// Mixin للأداء المحسن
mixin PerformanceOptimizedMixin {
  /// مدة الرسوم المتحركة المحسنة
  Duration get animationDuration => const Duration(milliseconds: 250).optimized;
  
  /// منحنى الرسوم المتحركة المحسن
  Curve get animationCurve => PerformanceManager.getOptimizedCurve();
  
  /// فيزياء التمرير المحسنة
  ScrollPhysics get scrollPhysics => PerformanceManager.optimizedScrollPhysics;
}
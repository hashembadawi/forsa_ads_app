# تحسينات ProGuard لتقليل حجم التطبيق

# الاحتفاظ بفئات Flutter الأساسية
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# الاحتفاظ بفئات Dart
-keep class **.** { *; }

# تحسين الكود
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# تقليل التحذيرات
-dontwarn io.flutter.**
-dontwarn androidx.**

# الاحتفاظ بالخصائص المهمة
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
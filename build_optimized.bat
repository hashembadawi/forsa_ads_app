@echo off
echo تطبيق فرصة - بناء APK محسن للحجم والأداء
echo =============================================

echo.
echo 1. تنظيف الملفات المؤقتة...
flutter clean

echo.
echo 2. جلب التبعيات...
flutter pub get

echo.
echo 3. تحليل الكود...
flutter analyze --no-fatal-infos

echo.
echo 4. بناء APK محسن (صغير الحجم)...
flutter build apk --split-per-abi --shrink --obfuscate --split-debug-info=build/debug_symbols

echo.
echo 5. عرض معلومات الملف المبني...
dir build\app\outputs\flutter-apk\*.apk

echo.
echo تم بناء التطبيق بنجاح! 
echo الملفات موجودة في: build\app\outputs\flutter-apk\
echo.
pause
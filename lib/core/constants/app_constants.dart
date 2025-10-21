class AppConstants {
  // App Info
  static const String appName = 'فرصة';
  static const String appNameEnglish = 'Forsa';
  static const String appTagline = 'تصفح أحدث الإعلانات، أو أنشئ إعلانك خلال ثوانٍ 👌';
  
  // Splash Screen
  static const Duration splashDuration = Duration(seconds: 2);
  
  // Shared Preferences Keys
  static const String isFirstTimeKey = 'isFirstTime';
  static const String isUserLoggedInKey = 'isUserLoggedIn';
  static const String userTokenKey = 'userToken';
  static const String userPhoneKey = 'userPhone';
  
  // Routes
  static const String splashRoute = '/';
  static const String welcomeRoute = '/welcome';
  static const String homeRoute = '/home';
  static const String authRoute = '/auth';
}
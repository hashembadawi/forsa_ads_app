import 'package:flutter/foundation.dart';
import 'exceptions.dart';

/// Error handler for the application
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// Handle and log errors
  void handleError(dynamic error, StackTrace? stackTrace) {
    if (kDebugMode) {
      debugPrint('🔴 Error occurred: $error');
      if (stackTrace != null) {
        debugPrint('📍 Stack trace: $stackTrace');
      }
    }

    // في الإنتاج، يمكن إرسال الأخطاء إلى خدمة مراقبة مثل Firebase Crashlytics
    _logToAnalytics(error, stackTrace);
  }

  /// Get user-friendly error message
  String getUserMessage(dynamic error) {
    if (error is NetworkException) {
      return _getNetworkErrorMessage(error);
    } else if (error is ValidationException) {
      return error.message;
    } else if (error is AuthException) {
      return _getAuthErrorMessage(error);
    } else if (error is StorageException) {
      return 'حدث خطأ في التخزين. يرجى المحاولة مرة أخرى.';
    } else if (error is AppException) {
      return error.message;
    } else {
      return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
    }
  }

  String _getNetworkErrorMessage(NetworkException error) {
    switch (error.statusCode) {
      case 400:
        return 'طلب غير صالح. يرجى التحقق من البيانات المدخلة.';
      case 401:
        return 'غير مصرح لك بالوصول. يرجى تسجيل الدخول مرة أخرى.';
      case 403:
        return 'ممنوع الوصول إلى هذا المورد.';
      case 404:
        return 'المورد المطلوب غير موجود.';
      case 500:
        return 'خطأ في الخادم. يرجى المحاولة لاحقاً.';
      default:
        return 'مشكلة في الاتصال بالإنترنت. يرجى التحقق من اتصالك.';
    }
  }

  String _getAuthErrorMessage(AuthException error) {
    if (error.message.contains('invalid')) {
      return 'بيانات الدخول غير صحيحة.';
    } else if (error.message.contains('expired')) {
      return 'انتهت صلاحية جلسة الدخول. يرجى تسجيل الدخول مرة أخرى.';
    } else {
      return 'خطأ في المصادقة. يرجى المحاولة مرة أخرى.';
    }
  }

  void _logToAnalytics(dynamic error, StackTrace? stackTrace) {
    // في الإنتاج، يمكن إضافة:
    // - Firebase Crashlytics
    // - Sentry
    // - أو أي خدمة مراقبة أخرى
    
    if (kDebugMode) {
      debugPrint('📊 Logging error to analytics: ${error.toString()}');
    }
  }
}

/// Extension لتسهيل استخدام ErrorHandler
extension ErrorHandlerExtension on dynamic {
  String toUserMessage() => ErrorHandler().getUserMessage(this);
  void logError([StackTrace? stackTrace]) => ErrorHandler().handleError(this, stackTrace);
}
import 'package:flutter/foundation.dart';

/// مستويات التسجيل المختلفة
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// نظام تسجيل شامل للتطبيق
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  // إعدادات التسجيل
  static const bool _enableLogging = kDebugMode;
  static const bool _enableFileLogging = false; // يمكن تفعيلها في المستقبل

  /// تسجيل رسالة عامة
  void log(String message, {LogLevel level = LogLevel.info, String? tag}) {
    if (!_enableLogging) return;

    final timestamp = DateTime.now().toIso8601String();
    final emoji = _getLogEmoji(level);
    final tagString = tag != null ? '[$tag] ' : '';
    
    final logMessage = '$emoji $timestamp - $tagString$message';
    
    switch (level) {
      case LogLevel.debug:
      case LogLevel.info:
        debugPrint(logMessage);
        break;
      case LogLevel.warning:
        debugPrint('⚠️  WARNING: $logMessage');
        break;
      case LogLevel.error:
      case LogLevel.critical:
        debugPrint('🚨 ERROR: $logMessage');
        break;
    }

    _logToFile(logMessage, level);
  }

  /// تسجيل معلومات التصحيح
  void debug(String message, {String? tag}) {
    log(message, level: LogLevel.debug, tag: tag);
  }

  /// تسجيل معلومات عامة
  void info(String message, {String? tag}) {
    log(message, level: LogLevel.info, tag: tag);
  }

  /// تسجيل تحذير
  void warning(String message, {String? tag}) {
    log(message, level: LogLevel.warning, tag: tag);
  }

  /// تسجيل خطأ
  void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    final errorMessage = error != null ? '$message - Error: $error' : message;
    log(errorMessage, level: LogLevel.error, tag: tag);
    
    if (stackTrace != null) {
      log('Stack trace: $stackTrace', level: LogLevel.error, tag: tag);
    }
  }

  /// تسجيل خطأ حرج
  void critical(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    final errorMessage = error != null ? '$message - Critical Error: $error' : message;
    log(errorMessage, level: LogLevel.critical, tag: tag);
    
    if (stackTrace != null) {
      log('Stack trace: $stackTrace', level: LogLevel.critical, tag: tag);
    }
  }

  /// تسجيل أداء العمليات
  void performance(String operation, Duration duration, {String? tag}) {
    final milliseconds = duration.inMilliseconds;
    log('⚡ Performance: $operation completed in ${milliseconds}ms', 
        level: LogLevel.info, tag: tag ?? 'PERFORMANCE');
  }

  /// تسجيل طلبات الشبكة
  void network(String method, String url, int statusCode, {Duration? duration, String? tag}) {
    final durationText = duration != null ? ' in ${duration.inMilliseconds}ms' : '';
    log('🌐 $method $url - Status: $statusCode$durationText', 
        level: LogLevel.info, tag: tag ?? 'NETWORK');
  }

  /// تسجيل أحداث المستخدم
  void userAction(String action, {Map<String, dynamic>? parameters, String? tag}) {
    final params = parameters?.isNotEmpty == true ? ' - Params: $parameters' : '';
    log('👤 User Action: $action$params', 
        level: LogLevel.info, tag: tag ?? 'USER_ACTION');
  }

  /// تسجيل تغييرات حالة التطبيق
  void stateChange(String from, String to, {String? context, String? tag}) {
    final contextText = context != null ? ' - Context: $context' : '';
    log('🔄 State Change: $from → $to$contextText', 
        level: LogLevel.info, tag: tag ?? 'STATE');
  }

  String _getLogEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.critical:
        return '🚨';
    }
  }

  void _logToFile(String message, LogLevel level) {
    if (!_enableFileLogging) return;
    
    // في المستقبل، يمكن إضافة تسجيل في ملف
    // للاحتفاظ بالسجلات حتى في الإنتاج
  }
}

/// مساعد سهولة الاستخدام
final logger = AppLogger();

/// Extension لتسهيل التسجيل من أي مكان
extension LoggerExtension on Object {
  void logInfo(String message, {String? tag}) => logger.info(message, tag: tag);
  void logDebug(String message, {String? tag}) => logger.debug(message, tag: tag);
  void logWarning(String message, {String? tag}) => logger.warning(message, tag: tag);
  void logError(String message, {dynamic error, StackTrace? stackTrace, String? tag}) => 
      logger.error(message, error: error, stackTrace: stackTrace, tag: tag);
}
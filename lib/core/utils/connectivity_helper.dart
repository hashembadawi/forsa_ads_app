import 'dart:io';

class ConnectivityHelper {
  /// Check if device has internet connection
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Check connection with custom host
  static Future<bool> canReachHost(String host) async {
    try {
      final result = await InternetAddress.lookup(host);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Get user-friendly error message based on connection status
  static Future<String> getConnectionErrorMessage() async {
    final hasConnection = await hasInternetConnection();
    if (!hasConnection) {
      return 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى';
    }
    return 'حدث خطأ في الاتصال. يرجى المحاولة لاحقاً';
  }
}

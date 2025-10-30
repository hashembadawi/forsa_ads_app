import 'package:dio/dio.dart';

class AuthService {
  final Dio _dio;
  // Note: Using localhost for token validation endpoint
  static const String baseUrl = 'https://sahbo-app-api.onrender.com';

  AuthService(this._dio);

  /// Validates the user token and returns user data
  /// 
  /// Returns a Map with:
  /// - 'valid': bool indicating if token is valid
  /// - 'user': Map with user data (userId, phoneNumber, firstName, lastName, etc.)
  /// 
  /// Throws Exception if request fails
  Future<Map<String, dynamic>> validateToken(String token) async {
    final url = '$baseUrl/api/user/validate-token';
    
    final options = Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
      validateStatus: (status) => status != null && status < 500,
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
      responseType: ResponseType.json,
    );

    try {
      final response = await _dio.get(url, options: options);
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      }
      
      // If not 200, consider token invalid
      throw Exception('فشل التحقق من صلاحية الجلسة (HTTP ${response.statusCode})');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg = e.message ?? 'network error';
      throw Exception('فشل التحقق من صلاحية الجلسة (${status ?? ''}) - $msg');
    } catch (e) {
      throw Exception('فشل التحقق من صلاحية الجلسة - $e');
    }
  }
}

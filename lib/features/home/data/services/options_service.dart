import 'package:dio/dio.dart';
import '../models/currency_option.dart';
import '../models/app_options.dart';

class OptionsService {
  final Dio _dio;
  static const String baseUrl = 'https://sahbo-app-api.onrender.com';

  OptionsService(this._dio);

  Future<AppOptions> fetchOptions() async {
    final url = '$baseUrl/api/options/';
    final reqOptions = Options(
      validateStatus: (status) => status != null && status < 500,
      sendTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      contentType: 'application/json',
      responseType: ResponseType.json,
    );
    try {
      final response = await _dio.get(url, options: reqOptions);
      if (response.statusCode == 200) {
        return _parseAppOptions(response.data);
      }
      throw Exception('فشل تحميل الخيارات (HTTP ${response.statusCode})');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg = e.message ?? 'network error';
      throw Exception('فشل تحميل الخيارات (${status ?? ''}) - $msg');
    } catch (e) {
      throw Exception('فشل تحميل الخيارات - $e');
    }
  }

  Future<List<CurrencyOption>> fetchCurrencies() async {
    // Reuse robust fetchOptions to avoid duplicating request logic
    final options = await fetchOptions();
    return options.currencies;
  }

  AppOptions _parseAppOptions(dynamic raw) {
    // Some backends wrap in { success, data: { ... } }
    final Map<String, dynamic> json =
        raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    final Map<String, dynamic> payload =
        (json['data'] is Map<String, dynamic>) ? json['data'] as Map<String, dynamic> : json;
    return AppOptions.fromJson(payload);
  }
}

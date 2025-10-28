import 'package:dio/dio.dart';
import '../models/currency_option.dart';

class OptionsService {
  final Dio _dio;
  static const String baseUrl = 'https://sahbo-app-api.onrender.com';

  OptionsService(this._dio);

  Future<List<CurrencyOption>> fetchCurrencies() async {
    final response = await _dio.get(
      '$baseUrl/api/options/',
      options: Options(validateStatus: (status) => status! < 500),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final List list = (data['currencies'] as List?) ?? [];
      return list.map((e) => CurrencyOption.fromJson(e)).toList();
    }
    throw Exception('فشل تحميل الخيارات');
  }
}

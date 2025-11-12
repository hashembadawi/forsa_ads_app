import 'dart:convert';

import 'package:dio/dio.dart';
import '../models/user_ad.dart';
import '../models/ad_details.dart';

class UserAdsService {
  final Dio _dio;
  static const String baseUrl = 'https://sahbo-app-api.onrender.com';

  UserAdsService(this._dio);

  Future<Map<String, dynamic>> addAd({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/ads/userAds/add',
        data: body,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('فشل إضافة الإعلان');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('لا يوجد اتصال بالإنترنت');
      } else if (e.response?.statusCode == 401) {
        throw Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
      } else if (e.response?.statusCode == 400) {
        throw Exception('بيانات الإعلان غير صحيحة');
      } else if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        throw Exception('خطأ في الخادم. يرجى المحاولة لاحقاً');
      } else {
        throw Exception('حدث خطأ أثناء إضافة الإعلان');
      }
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  Future<void> updateAd({
    required String adId,
    required String token,
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _dio.put(
        '$baseUrl/api/ads/userAds/update/$adId',
        data: body,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('فشل تعديل الإعلان');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('لا يوجد اتصال بالإنترنت');
      } else if (e.response?.statusCode == 401) {
        throw Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
      } else if (e.response?.statusCode == 404) {
        throw Exception('لم يتم العثور على الإعلان');
      } else if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        throw Exception('خطأ في الخادم. يرجى المحاولة لاحقاً');
      } else {
        throw Exception('حدث خطأ أثناء تعديل الإعلان');
      }
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  Future<Map<String, dynamic>> fetchUserAds({
    required String userId,
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/ads/userAds/$userId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      final List<UserAd> ads = (response.data['ads'] as List)
          .map((ad) => UserAd.fromJson(ad))
          .toList();

      // Include top-level images array (if present) so callers can access
      // server-provided images that are not embedded per-ad.
      final List<dynamic> topImages = response.data['images'] is List ? response.data['images'] as List<dynamic> : [];

      return {
        'ads': ads,
        'total': response.data['total'],
        'page': response.data['page'],
        'limit': response.data['limit'],
        'images': topImages,
      };
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('لا يوجد اتصال بالإنترنت');
      } else if (e.response?.statusCode == 401) {
        throw Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
      } else if (e.response?.statusCode == 404) {
        throw Exception('لم يتم العثور على الإعلانات');
      } else if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        throw Exception('خطأ في الخادم. يرجى المحاولة لاحقاً');
      } else {
        throw Exception('حدث خطأ أثناء تحميل الإعلانات');
      }
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  /// Fetch public ads with pagination (no auth required)
  Future<Map<String, dynamic>> fetchAds({
    int page = 1,
    int limit = 15,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/ads',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );

      final List<UserAd> ads = (response.data['ads'] as List)
          .map((ad) => UserAd.fromJson(ad))
          .toList();

      // Also include any top-level images array returned by the API
      // so callers (like the PublicAdsProvider) can show a slider from
      // server-provided images that aren't embedded per-ad.
      final List<dynamic> topImages =
          response.data['images'] is List ? response.data['images'] as List<dynamic> : [];

      return {
        'ads': ads,
        'total': response.data['total'],
        'page': response.data['page'],
        'limit': response.data['limit'],
        'images': topImages,
      };
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('لا يوجد اتصال بالإنترنت');
      } else if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        throw Exception('خطأ في الخادم. يرجى المحاولة لاحقاً');
      } else {
        throw Exception('حدث خطأ أثناء تحميل الإعلانات');
      }
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  /// Fetch a single ad by id
  Future<UserAd> fetchAdById({required String adId}) async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/ads/getAdById/$adId',
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        // Keep existing behavior for backward compatibility and return UserAd
        dynamic raw = response.data;
        try {
          if (raw is String) raw = jsonDecode(raw);
        } catch (_) {}

        Map<String, dynamic> data = {};
        if (raw is Map && raw['ad'] != null) {
          var adRaw = raw['ad'];
          try {
            if (adRaw is String) adRaw = jsonDecode(adRaw);
          } catch (_) {}
          if (adRaw is Map) data = Map<String, dynamic>.from(adRaw);
        } else if (raw is Map) {
          data = Map<String, dynamic>.from(raw);
        }

        return UserAd.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('لم يتم العثور على الإعلان');
      } else {
        throw Exception('تعذر جلب بيانات الإعلان');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('لا يوجد اتصال بالإنترنت');
      } else if (e.response?.statusCode == 401) {
        throw Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
      } else if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        throw Exception('خطأ في الخادم. يرجى المحاولة لاحقاً');
      } else {
        throw Exception('حدث خطأ أثناء جلب تفاصيل الإعلان');
      }
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  /// Fetch ad details using AdDetails model. This is the preferred
  /// method when opening the details screen (full rich payload).
  Future<AdDetails> fetchAdDetails({required String adId}) async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/ads/getAdById/$adId',
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        dynamic raw = response.data;
        try {
          if (raw is String) raw = jsonDecode(raw);
        } catch (_) {}

        Map<String, dynamic> data = {};
        if (raw is Map && raw['ad'] != null) {
          var adRaw = raw['ad'];
          try {
            if (adRaw is String) adRaw = jsonDecode(adRaw);
          } catch (_) {}
          if (adRaw is Map) data = Map<String, dynamic>.from(adRaw);
        } else if (raw is Map) {
          data = Map<String, dynamic>.from(raw);
        }

        return AdDetails.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('لم يتم العثور على الإعلان');
      } else {
        throw Exception('تعذر جلب بيانات الإعلان');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('لا يوجد اتصال بالإنترنت');
      } else if (e.response?.statusCode == 401) {
        throw Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
      } else if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        throw Exception('خطأ في الخادم. يرجى المحاولة لاحقاً');
      } else {
        throw Exception('حدث خطأ أثناء جلب تفاصيل الإعلان');
      }
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  Future<void> deleteAd({
    required String adId,
    required String token,
  }) async {
    try {
      final response = await _dio.delete(
        '$baseUrl/api/ads/userAds/$adId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('فشل حذف الإعلان');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('لا يوجد اتصال بالإنترنت');
      } else if (e.response?.statusCode == 401) {
        throw Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
      } else if (e.response?.statusCode == 404) {
        throw Exception('لم يتم العثور على الإعلان');
      } else if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        throw Exception('خطأ في الخادم. يرجى المحاولة لاحقاً');
      } else {
        throw Exception('حدث خطأ أثناء حذف الإعلان');
      }
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }
}

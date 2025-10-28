import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../data/models/user_ad.dart';
import '../../data/services/user_ads_service.dart';

// State class
class UserAdsState {
  final List<UserAd> ads;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalAds;
  final bool hasMore;
  final bool isNoInternet;

  UserAdsState({
    this.ads = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalAds = 0,
    this.hasMore = true,
    this.isNoInternet = false,
  });

  UserAdsState copyWith({
    List<UserAd>? ads,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalAds,
    bool? hasMore,
    bool? isNoInternet,
  }) {
    return UserAdsState(
      ads: ads ?? this.ads,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalAds: totalAds ?? this.totalAds,
      hasMore: hasMore ?? this.hasMore,
      isNoInternet: isNoInternet ?? this.isNoInternet,
    );
  }
}

// StateNotifier
class UserAdsNotifier extends StateNotifier<UserAdsState> {
  final UserAdsService _service;

  UserAdsNotifier(this._service) : super(UserAdsState());

  Future<void> fetchUserAds({bool refresh = false}) async {
    if (refresh) {
      state = UserAdsState(isLoading: true);
    } else if (state.isLoading || !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null, isNoInternet: false);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final token = prefs.getString('user_token');

      if (userId == null || token == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'يرجى تسجيل الدخول أولاً',
        );
        return;
      }

      final page = refresh ? 1 : state.currentPage;
      final result = await _service.fetchUserAds(
        userId: userId,
        token: token,
        page: page,
        limit: 10,
      );

      final newAds = result['ads'] as List<UserAd>;
      final total = result['total'] as int;

      state = state.copyWith(
        ads: refresh ? newAds : [...state.ads, ...newAds],
        isLoading: false,
        currentPage: page + 1,
        totalAds: total,
        hasMore: (refresh ? newAds.length : state.ads.length + newAds.length) < total,
        isNoInternet: false,
      );
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      final isNoInternet = errorMessage.contains('لا يوجد اتصال بالإنترنت');
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
        isNoInternet: isNoInternet,
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await fetchUserAds();
  }
}

// Provider
final userAdsProvider = StateNotifierProvider<UserAdsNotifier, UserAdsState>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ),
  );
  final service = UserAdsService(dio);
  return UserAdsNotifier(service);
});

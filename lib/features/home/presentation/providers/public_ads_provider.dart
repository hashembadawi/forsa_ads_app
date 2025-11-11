import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/models/user_ad.dart';
import '../../data/services/user_ads_service.dart';

class PublicAdsState {
  final List<UserAd> ads;
  final List<Map<String, dynamic>> images;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalAds;
  final bool hasMore;

  PublicAdsState({
    this.ads = const [],
    this.images = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalAds = 0,
    this.hasMore = true,
  });

  PublicAdsState copyWith({
    List<UserAd>? ads,
    List<Map<String, dynamic>>? images,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalAds,
    bool? hasMore,
  }) {
    return PublicAdsState(
      ads: ads ?? this.ads,
      images: images ?? this.images,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalAds: totalAds ?? this.totalAds,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class PublicAdsNotifier extends StateNotifier<PublicAdsState> {
  final UserAdsService _service;

  PublicAdsNotifier(this._service) : super(PublicAdsState());

  Future<void> fetchAds({bool refresh = false, int limit = 15}) async {
    if (refresh) {
      state = PublicAdsState(isLoading: true);
    } else if (state.isLoading || !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final page = refresh ? 1 : state.currentPage;
      final result = await _service.fetchAds(page: page, limit: limit);

      final newAds = result['ads'] as List<UserAd>;
      final total = result['total'] as int;
      final topImages = (result['images'] as List<dynamic>?)
              ?.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
              .toList() ??
          <Map<String, dynamic>>[];

      state = state.copyWith(
        ads: refresh ? newAds : [...state.ads, ...newAds],
        images: refresh ? topImages : [...state.images, ...topImages],
        isLoading: false,
        currentPage: page + 1,
        totalAds: total,
        hasMore: (refresh ? newAds.length : state.ads.length + newAds.length) < total,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadMore({int limit = 15}) async {
    if (!state.hasMore || state.isLoading) return;
    await fetchAds(limit: limit);
  }
}

final publicAdsProvider = StateNotifierProvider<PublicAdsNotifier, PublicAdsState>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ),
  );
  final service = UserAdsService(dio);
  return PublicAdsNotifier(service);
});
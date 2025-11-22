
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/notifications.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../data/services/user_ads_service.dart';
import '../../data/models/user_ad.dart';
import '../widgets/home_ad_card.dart';
import '../../../../core/ui/app_keys.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesTab extends ConsumerStatefulWidget {
  const FavoritesTab({super.key});

  @override
  ConsumerState<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends ConsumerState<FavoritesTab> {
  bool _isLoading = true;
  String? _error;
  List<UserAd> _ads = [];
  int _page = 1;
  int _limit = 10;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _ads = [];
      _total = 0;
    }
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final appState = ref.read(appStateProvider);
      final token = appState.userToken;
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _error = 'يجب تسجيل الدخول لعرض المفضلات';
            _isLoading = false;
          });
        }
        return;
      }

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ));
      final service = UserAdsService(dio);
      final res = await service.fetchFavorites(token: token, page: _page, limit: _limit);
      final List<UserAd> fetched = (res['ads'] as List<dynamic>).cast<UserAd>();
      if (!mounted) return;
      setState(() {
        if (_page == 1) _ads = fetched; else _ads.addAll(fetched);
        _total = res['total'] ?? _total;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openAd(UserAd selected) async {
    final notifyCtx = appNavigatorKey.currentContext ?? context;
    final fallbackRouter = GoRouter.of(context);

    try {
      Notifications.showLoading(notifyCtx, message: 'جاري التحميل...');
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      );
      final service = UserAdsService(dio);
      final appState = ref.read(appStateProvider);
      late final fetched;
      if (appState.isUserLoggedIn && appState.userToken != null && appState.userToken!.isNotEmpty) {
        fetched = await service.fetchAdDetailsForUser(adId: selected.id, token: appState.userToken!);
      } else {
        fetched = await service.fetchAdDetails(adId: selected.id);
      }
      Notifications.hideLoading(notifyCtx);

      final globalCtx = appNavigatorKey.currentContext;
      if (globalCtx != null) {
        GoRouter.of(globalCtx).push(AppRoutes.adDetails, extra: fetched);
      } else {
        fallbackRouter.push(AppRoutes.adDetails, extra: fetched);
      }
    } catch (e) {
      try {
        Notifications.hideLoading(notifyCtx);
      } catch (_) {}
      final msg = e.toString().replaceFirst('Exception: ', '');
      try {
        Notifications.showError(notifyCtx, msg);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.navFavorites)),
      body: RefreshIndicator(
        onRefresh: () async => await _loadFavorites(refresh: true),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _isLoading
              ? ListView.separated(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(height: 14, width: double.infinity, color: Colors.grey[300]),
                                    const SizedBox(height: 8),
                                    Container(height: 12, width: 120, color: Colors.grey[300]),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(height: 10, width: 80, color: Colors.grey[300]),
                                        const SizedBox(width: 8),
                                        Container(height: 10, width: 40, color: Colors.grey[300]),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(width: 100, height: 80, color: Colors.grey[300]),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                  : _ads.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.favorite_outline, size: 64, color: AppTheme.iconInactiveColor),
                              SizedBox(height: 16),
                              Text(AppStrings.favoritesEmpty),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _ads.length + (_total > _ads.length ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, idx) {
                            if (idx < _ads.length) {
                              final ad = _ads[idx];
                              return Row(
                                children: [
                                  Expanded(child: HomeAdCard(ad: ad, onTap: (_) => _openAd(ad))),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 44,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      tooltip: 'حذف من المفضلة',
                                      onPressed: () async {
                                        final confirm = await Notifications.showConfirm(
                                          context,
                                          'هل تود إزالة هذا الإعلان من المفضلة؟',
                                          confirmText: AppStrings.yes,
                                          cancelText: AppStrings.cancel,
                                        );

                                        if (confirm != true) return;

                                        try {
                                          final notifyCtx = appNavigatorKey.currentContext ?? context;
                                          Notifications.showLoading(notifyCtx, message: 'جاري الحذف...');

                                          final dio = Dio(
                                            BaseOptions(
                                              connectTimeout: const Duration(seconds: 15),
                                              receiveTimeout: const Duration(seconds: 15),
                                              sendTimeout: const Duration(seconds: 15),
                                            ),
                                          );
                                          final service = UserAdsService(dio);
                                          final appState = ref.read(appStateProvider);
                                          final token = appState.userToken;
                                          final prefs = await SharedPreferences.getInstance();
                                          final userId = prefs.getString('userId') ?? '';

                                          if (token == null || token.isEmpty || userId.isEmpty) {
                                            Notifications.hideLoading(notifyCtx);
                                            Notifications.showError(notifyCtx, 'يجب تسجيل الدخول لإجراء هذا الإجراء');
                                            return;
                                          }

                                          await service.deleteFavorite(token: token, userId: userId, adId: ad.id);
                                          Notifications.hideLoading(notifyCtx);

                                          // refresh list after deletion
                                          await _loadFavorites(refresh: true);
                                        } catch (e) {
                                          final msg = e.toString().replaceFirst('Exception: ', '');
                                          try {
                                            final notifyCtx = appNavigatorKey.currentContext ?? context;
                                            Notifications.hideLoading(notifyCtx);
                                            Notifications.showError(notifyCtx, msg);
                                          } catch (_) {}
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }
                            // Load more button
                            return SizedBox(
                              height: 56,
                              child: Center(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    _page += 1;
                                    await _loadFavorites();
                                  },
                                  child: const Text('عرض المزيد'),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}

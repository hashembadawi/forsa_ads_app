import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/user_ad.dart';
import '../../presentation/widgets/home_ad_card.dart';
import '../../data/services/user_ads_service.dart';
import '../../../../core/ui/notifications.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/ui/app_keys.dart';
import '../../../../shared/providers/app_state_provider.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String title;
  const SearchResultsScreen({Key? key, required this.title}) : super(key: key);

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  bool _loading = true;
  String? _error;
  List<UserAd> _ads = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final ctx = context;
    try {
      Notifications.showLoading(ctx, message: 'جاري البحث...');
      final dio = Dio();
      final resp = await dio.get(
        'https://sahbo-app-api.onrender.com/api/ads/search-by-title',
        queryParameters: {'title': widget.title, 'page': 1, 'limit': 10},
      );

      final data = resp.data as Map<String, dynamic>?;
      final adsJson = data?['ads'] as List<dynamic>? ?? [];
      final List<UserAd> ads = adsJson.map((e) => UserAd.fromJson(Map<String, dynamic>.from(e as Map))).toList();

      setState(() {
        _ads = ads;
        _loading = false;
      });
      Notifications.hideLoading(ctx);
    } catch (e) {
      try {
        Notifications.hideLoading(ctx);
      } catch (_) {}
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('نتائج البحث: "${widget.title}"')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('حدث خطأ: $_error'),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _fetch, child: const Text('إعادة المحاولة')),
                      ],
                    ),
                  )
                : _ads.isEmpty
                    ? Center(child: Text('لا توجد نتائج لـ "${widget.title}"'))
                    : RefreshIndicator(
                        onRefresh: _fetch,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _ads.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final ad = _ads[i];
                            return HomeAdCard(
                              ad: ad,
                              onTap: (selected) async {
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
                              },
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}

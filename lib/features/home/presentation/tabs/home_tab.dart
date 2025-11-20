import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/strings.dart';
// theme import removed (not needed for carousel background)
import '../providers/public_ads_provider.dart';
import 'dart:async';
import 'dart:convert';

import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../widgets/home_ad_card.dart';
import '../../data/services/user_ads_service.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../../../core/ui/notifications.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/ui/app_keys.dart';
import '../../../../core/widgets/async_image_with_shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import '../screens/search_options_screen.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publicState = ref.watch(publicAdsProvider);

    // Trigger initial load of public ads when entering the tab if not already initialized
    if (!publicState.initialized && !publicState.isLoading) {
      Future.microtask(() => ref.read(publicAdsProvider.notifier).fetchAds(refresh: true));
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppConstants.appName)),
      body: RefreshIndicator(
        onRefresh: () async => await ref.read(publicAdsProvider.notifier).fetchAds(refresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image slider (replaces previous greeting section)
              AdsImageCarousel(),
              const SizedBox(height: 12),

              // Search bar (tappable) placed under the slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchOptionsScreen()));
                  },
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.black54),
                        const SizedBox(width: 12),
                        Expanded(child: Text('ابحث عن إعلان أو اختيار خيارات البحث...', style: TextStyle(color: Colors.grey[700]))),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black26),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 12),

              // Recent ads
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.recentAdsTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    // Recent ads loaded from backend
                    _buildRecentAds(),
                  ],
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentAds() {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(publicAdsProvider);

      if (state.isLoading && state.ads.isEmpty) {
        // Show shimmer placeholders as horizontal rows while loading initial data
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            return Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // Text placeholders
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 16, width: double.infinity, color: Colors.grey[300]),
                            const SizedBox(height: 6),
                            Container(height: 14, width: 120, color: Colors.grey[300]),
                            const SizedBox(height: 6),
                            Container(height: 12, width: 80, color: Colors.grey[300]),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Image placeholder
                      Container(width: 110, height: 110, color: Colors.grey[300]),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }

      if (state.error != null && state.ads.isEmpty) {
        return Column(
          children: [
            Text(state.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () => ref.read(publicAdsProvider.notifier).fetchAds(refresh: true), child: const Text('إعادة المحاولة')),
          ],
        );
      }

      // Handle case: backend returned no ads (empty result) and not loading.
      if (!state.isLoading && state.ads.isEmpty) {
        // Center the empty state (icon, message, button) vertically
        final totalHeight = MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SizedBox(
            height: totalHeight,
            child: Align(
              alignment: const Alignment(0, -0.85), // move further up (near top area)
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[500]),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد إعلانات للعرض حالياً',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.read(publicAdsProvider.notifier).fetchAds(refresh: true),
                    child: const Text('تحديث'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Show list of ads (one per row); load more button at the end
      return Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.ads.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final ad = state.ads[index];
              return HomeAdCard(
                ad: ad,
                onTap: (selected) async {
                  // Capture contexts/router before any await to avoid using
                  // the local BuildContext across async gaps (linter warning).
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
                    // Fetch full ad details (new model)
                    final appState = ref.read(appStateProvider);
                    late final fetched;
                    if (appState.isUserLoggedIn && appState.userToken != null && appState.userToken!.isNotEmpty) {
                      fetched = await service.fetchAdDetailsForUser(adId: selected.id, token: appState.userToken!);
                    } else {
                      fetched = await service.fetchAdDetails(adId: selected.id);
                    }
                    Notifications.hideLoading(notifyCtx);

                    // Prefer global navigator context if available, otherwise
                    // use the router captured before the await.
                    final globalCtx = appNavigatorKey.currentContext;
                    if (globalCtx != null) {
                      GoRouter.of(globalCtx).push(AppRoutes.adDetails, extra: fetched);
                    } else {
                      fallbackRouter.push(AppRoutes.adDetails, extra: fetched);
                    }
                  } catch (e) {
                    Notifications.hideLoading(notifyCtx);
                    final msg = e.toString().replaceFirst('Exception: ', '');
                    try {
                      Notifications.showError(notifyCtx, msg);
                    } catch (_) {}
                  }
                },
              );
            },
          ),
          const SizedBox(height: 8),
          if (state.hasMore)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.isLoading ? null : () => ref.read(publicAdsProvider.notifier).loadMore(),
                child: state.isLoading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('عرض المزيد'),
              ),
            ),
        ],
      );
    });
  }
}

class AdsImageCarousel extends ConsumerStatefulWidget {
  const AdsImageCarousel({Key? key}) : super(key: key);

  @override
  ConsumerState<AdsImageCarousel> createState() => _AdsImageCarouselState();
}

class _AdsImageCarouselState extends ConsumerState<AdsImageCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  List<String> _images = [];
  int _currentIndex = 0;

  void _startTimer() {
    _timer?.cancel();
    if (_images.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_controller.hasClients || _images.isEmpty) return;
      final next = (_currentIndex + 1) % _images.length;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // Attempt robust base64 decode: try standard base64, url-safe base64,
  // and fix padding if needed. Returns null on failure.
  Uint8List? _tryDecodeBase64(String s) {
    try {
      // Remove any non-base64 characters (safety)
      final cleaned = s.replaceAll(RegExp(r'[^A-Za-z0-9+/=_-]'), '');

      // Try standard decode first
      try {
        return base64Decode(cleaned);
      } catch (_) {}

      // Try URL-safe decode
      try {
        return base64Url.decode(cleaned);
      } catch (_) {}

      // Try adding padding
      var padded = cleaned;
      while (padded.length % 4 != 0) {
        padded += '=';
        if (padded.length > cleaned.length + 4) break;
      }
      try {
        return base64Decode(padded);
      } catch (_) {}

      // Last attempt: replace url-safe chars then decode
      final replaced = cleaned.replaceAll('-', '+').replaceAll('_', '/');
      try {
        return base64Decode(replaced);
      } catch (_) {}

    } catch (e) {
      if (kDebugMode) debugPrint('AdsImageCarousel: unexpected decode error $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(publicAdsProvider);

    // Use ONLY the top-level `images` array returned by the API (state.images).
    // Do not include per-ad thumbnails or ad.images here — user requested
    // the slider to show only the top-level `images` entries.
    final List<String> images = [];
    try {
      for (final m in state.images) {
        final content = (m['content'] ?? '').toString().trim();
        if (content.isNotEmpty) images.add(content);
      }
    } catch (_) {}

    // Remove duplicates while preserving order
    final seen = <String>{};
    final filtered = <String>[];
    for (final s in images) {
      if (s.isNotEmpty && !seen.contains(s)) {
        seen.add(s);
        filtered.add(s);
      }
    }

    final aggregated = filtered;

    // If images changed, update and restart timer after frame
    if (!listEquals(aggregated, _images)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _images = aggregated;
          _currentIndex = 0;
          if (_controller.hasClients) {
            _controller.jumpToPage(0);
          }
        });
        _startTimer();
      });
    }

    if (_images.isEmpty) {
      // If still loading, show shimmer placeholder. If loading finished but
      // there are no images from backend, show an empty-state banner.
      if (state.isLoading) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Card(
            elevation: 2,
            color: AppTheme.surfaceColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              height: 180,
              child: Center(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      // Not loading and no images -> show friendly empty banner
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Card(
          elevation: 2,
          color: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            height: 180,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'لا توجد صور للعرض',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Card(
        elevation: 2,
        color: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          height: 180,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
          // PageView shows images edge-to-edge without an outer gradient/background
          PageView.builder(
            controller: _controller,
            itemCount: _images.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              var content = _images[index];
              // If the content is a data URI like 'data:image/png;base64,...', strip the prefix.
              if (content.contains(',')) {
                final parts = content.split(',');
                content = parts.last;
              }

              // sanitize
              content = content.trim();
              content = content.replaceAll(RegExp(r'\s+'), '');

              Uint8List? decoded;
              try {
                decoded = _tryDecodeBase64(content);
              } catch (e) {
                if (kDebugMode) debugPrint('AdsImageCarousel: _tryDecodeBase64 threw: $e');
              }

              if (decoded != null) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    AsyncImageWithShimmer(imageBytes: decoded, fit: BoxFit.cover),
                  ],
                );
              }

              // fallback placeholder
              return Container(color: Colors.grey[300]);
            },
          ),

          // Indicators
          Positioned(
            bottom: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_images.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == i ? 10 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(_currentIndex == i ? 0.95 : 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              }),
            ),
          ),

          // debug overlay removed per user request
        ],
              ),
            ),
          ),
        );
  }
}

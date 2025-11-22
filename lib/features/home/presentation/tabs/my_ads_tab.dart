import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/no_internet_widget.dart';
import '../../../../shared/utils/network_utils.dart';
import '../providers/user_ads_provider.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/user_ad_card.dart';

class MyAdsTab extends ConsumerStatefulWidget {
  const MyAdsTab({super.key});

  @override
  ConsumerState<MyAdsTab> createState() => _MyAdsTabState();
}

class _MyAdsTabState extends ConsumerState<MyAdsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load ads on first build
    Future.microtask(() {
      ref.read(userAdsProvider.notifier).fetchUserAds(refresh: true);
    });

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(userAdsProvider.notifier).loadMore();
    }
  }

  void _showErrorSnackBar(String message, {bool isNoInternet = false}) {
    if (!mounted) return;

    final displayMessage = isNoInternet
        ? message
        : 'حدث خطأ ما يرجى المحاولة مجددا';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isNoInternet ? Icons.wifi_off_rounded : Icons.error_outline,
              color: Theme.of(context).colorScheme.onError,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(displayMessage),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'إعادة',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            ref.read(userAdsProvider.notifier).fetchUserAds(refresh: true);
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userAdsProvider);

    // Show error snackbar when there's an error and we have existing ads
    ref.listen<UserAdsState>(userAdsProvider, (previous, current) {
      if (current.error != null && current.ads.isNotEmpty && !current.isLoading) {
        _showErrorSnackBar(current.error!, isNoInternet: current.isNoInternet);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(AppStrings.navMyAds),
            if (state.totalAds > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.totalAds}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(userAdsProvider.notifier).fetchUserAds(refresh: true);
        },
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(UserAdsState state) {
    // Show no internet state (also treat certain error messages as no-internet)
    if ((state.isNoInternet || looksLikeNoInternet(state.error)) && state.ads.isEmpty) {
      return NoInternetWidget(
        onRetry: () => ref.read(userAdsProvider.notifier).fetchUserAds(refresh: true),
      );
    }

    // Show error state
    if (state.error != null && state.ads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.isNoInternet ? Icons.wifi_off_rounded : Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'حدث خطأ ما يرجى المحاولة مجددا',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.errorColor),
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'إعادة المحاولة',
              onPressed: () {
                ref.read(userAdsProvider.notifier).fetchUserAds(refresh: true);
              },
              size: AppButtonSize.large,
            ),
          ],
        ),
      );
    }

    // Show loading shimmer on first load (compact horizontal rows)
    if (state.isLoading && state.ads.isEmpty) {
      return ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(height: 14, width: double.infinity, color: Colors.grey[300]),
                          const SizedBox(height: 6),
                          Container(height: 12, width: 100, color: Colors.grey[300]),
                          const SizedBox(height: 6),
                          Container(height: 12, width: 80, color: Colors.grey[300]),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Image placeholder
                    Container(width: 72, height: 72, color: Colors.grey[300]),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    // Show empty state
    if (state.ads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.campaign_outlined,
              size: 64,
              color: AppTheme.iconInactiveColor,
            ),
            const SizedBox(height: 16),
            const Text(AppStrings.myAdsEmpty),
            const SizedBox(height: 16),
            AppButton(
              text: 'أضف أول إعلان',
              icon: Icons.add,
              onPressed: () {
                // Navigate to add ad screen
              },
              size: AppButtonSize.large,
            ),
          ],
        ),
      );
    }

    // Show ads list (one ad per row) with pagination
    return ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      itemCount: state.ads.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        // Show loading indicator at the end
        if (index == state.ads.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          );
        }

        return UserAdCard(ad: state.ads[index]);
      },
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/user_ads_provider.dart';
import '../widgets/user_ad_card.dart';
import '../widgets/ad_card_shimmer.dart';

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
    // Show no internet state
    if (state.isNoInternet && state.ads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 80,
              color: AppTheme.iconInactiveColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'لا يوجد اتصال بالإنترنت',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'إعادة المحاولة',
              icon: Icons.refresh,
              onPressed: () {
                ref.read(userAdsProvider.notifier).fetchUserAds(refresh: true);
              },
              size: AppButtonSize.large,
            ),
          ],
        ),
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

    // Show loading shimmer on first load
    if (state.isLoading && state.ads.isEmpty) {
      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: UserAdCard.kGridAspectRatio,
          crossAxisSpacing: 6,
          mainAxisSpacing: 8,
        ),
        itemCount: 6, // Show 6 shimmer cards
        itemBuilder: (context, index) => const AdCardShimmer(),
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

    // Show ads grid with pagination
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: UserAdCard.kGridAspectRatio,
        crossAxisSpacing: 6,
        mainAxisSpacing: 8,
      ),
      itemCount: state.ads.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at the end
        if (index == state.ads.length) {
          return Center(
            child: const Padding(
              padding: EdgeInsets.all(16),
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


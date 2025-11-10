import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../providers/public_ads_provider.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/home_ad_card.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final publicState = ref.watch(publicAdsProvider);

    // Trigger initial load of public ads when entering the tab if not already loaded
    if (publicState.ads.isEmpty && !publicState.isLoading && publicState.error == null) {
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
              // User greeting (show full name when available)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(builder: (context) {
                      String greeting = AppStrings.welcomeGuest;
                      if (appState.isUserLoggedIn) {
                        final first = appState.userFirstName ?? '';
                        final last = appState.userLastName ?? '';
                        final fullName = '${first.trim()} ${last.trim()}'.trim();
                        greeting = fullName.isNotEmpty ? '${AppStrings.welcomeRegistered} $fullName' : AppStrings.welcomeRegistered;
                      }
                      return Text(
                        greeting,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      );
                    }),
                    const SizedBox(height: 8),
                    Text(
                      appState.isUserLoggedIn ? AppStrings.welcomeSubtitleRegistered : AppStrings.welcomeSubtitleGuest,
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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
                    const SizedBox(height: 16),
                    // Recent ads loaded from backend
                    _buildRecentAds(),
                  ],
                ),
              ),

              const SizedBox(height: 20),
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

      // Show list of ads (one per row); load more button at the end
      return Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.ads.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              return HomeAdCard(ad: state.ads[index]);
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

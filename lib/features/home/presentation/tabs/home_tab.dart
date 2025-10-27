import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/app_state_provider.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
      ),
      body: SingleChildScrollView(
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
                  // Use AppState for names for speed (avoid SharedPreferences reads in UI)
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Text(
                    appState.isUserLoggedIn
                        ? AppStrings.welcomeSubtitleRegistered
                        : AppStrings.welcomeSubtitleGuest,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRecentAds(),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAds() {
    // Sample ads data
    final ads = [
      {
        'title': 'BMW X5 موديل 2020',
        'price': '45,000',
        'location': 'دمشق',
        'image': Icons.directions_car,
      },
      {
        'title': 'آيفون 14 برو ماكس',
        'price': '1,200',
        'location': 'حلب',
        'image': Icons.phone_iphone,
      },
      {
        'title': 'شقة 3 غرف للبيع',
        'price': '85,000',
        'location': 'اللاذقية',
        'image': Icons.home,
      },
    ];

    return Column(
      children: ads.map((ad) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Icon(
                ad['image'] as IconData,
                color: AppTheme.primaryColor,
              ),
            ),
            title: Text(
              ad['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Text(ad['location'] as String),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${ad['price']} \$',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            onTap: () {
              // TODO: Navigate to ad details
            },
          ),
        );
      }).toList(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/app_state_provider.dart';
import '../../../core/constants/strings.dart';
import '../../../core/ui/notifications.dart';
import 'tabs/home_tab.dart';
import 'tabs/favorites_tab.dart';
import 'tabs/add_ad_tab.dart';
import 'tabs/my_ads_tab.dart';
import 'tabs/profile_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int? initialIndex;
  const HomeScreen({super.key, this.initialIndex});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const HomeTab(),
    const FavoritesTab(),
    const AddAdTab(),
    const MyAdsTab(),
    const ProfileTab(),
  ];

  // Navigation uses explicit setState calls in the UI handlers.

  @override
  void initState() {
    super.initState();
    if (widget.initialIndex != null) {
      _selectedIndex = widget.initialIndex!.clamp(0, 4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fabSize = 64.0;
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_selectedIndex],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: fabSize,
        height: fabSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: FloatingActionButton(
          onPressed: () async {
            final appState = ref.read(appStateProvider);
            if (!appState.isUserLoggedIn) {
              final ok = await Notifications.showConfirm(context, AppStrings.loginRequiredMessage, confirmText: AppStrings.loginLabel, cancelText: AppStrings.no);
              if (ok == true) {
                final result = await context.pushNamed(RouteNames.login, extra: {'returnTab': 2});
                if (result is int) {
                  setState(() => _selectedIndex = result.clamp(0, 4));
                }
              }
              return;
            }
            setState(() => _selectedIndex = 2);
          },
          shape: const CircleBorder(),
          elevation: 6,
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.add, size: 32),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _threeNavItem(icon: Icons.home_rounded, label: AppStrings.navHome, index: 0),
                    _threeNavItem(icon: Icons.favorite_rounded, label: AppStrings.navFavorites, index: 1),
                  ],
                ),
              ),
              const SizedBox(width: 72),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _threeNavItem(icon: Icons.campaign_rounded, label: AppStrings.navMyAds, index: 3),
                    _threeNavItem(icon: Icons.person_rounded, label: AppStrings.navProfile, index: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _threeNavItem({required IconData icon, required String label, required int index}) {
    final selected = _selectedIndex == index;
    return InkWell(
      onTap: () async {
        // Protect certain tabs from guest users
        final appState = ref.read(appStateProvider);
        if (!appState.isUserLoggedIn && (index == 1 || index == 2 || index == 3)) {
          final ok = await Notifications.showConfirm(context, AppStrings.loginRequiredMessage, confirmText: AppStrings.loginLabel, cancelText: AppStrings.no);
          if (ok == true) {
            final result = await context.pushNamed(RouteNames.login, extra: {'returnTab': index});
            if (result is int) {
              setState(() => _selectedIndex = result.clamp(0, 4));
            }
          }
          return;
        }
        setState(() => _selectedIndex = index);
      },
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: selected ? 34 : 28, color: selected ? AppTheme.primaryColor : Colors.grey),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: selected ? 12 : 11, color: selected ? AppTheme.primaryColor : Colors.grey)),
          ],
        ),
      ),
    );
  }
}
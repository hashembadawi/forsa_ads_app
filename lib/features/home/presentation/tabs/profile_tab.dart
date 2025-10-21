import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/notifications.dart';
import '../../../../shared/providers/app_state_provider.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // User info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryColor,
                    child: Icon(Icons.person, size: 40, color: AppTheme.surfaceColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    appState.isUserLoggedIn 
                        ? (appState.userPhone ?? AppStrings.registeredLabel)
                        : AppStrings.guestLabel,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    appState.isUserLoggedIn ? AppStrings.registeredLabel : AppStrings.guestLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Menu items
          if (!appState.isUserLoggedIn) ...[
            ListTile(
              leading: const Icon(Icons.login),
              title: Text(AppStrings.loginLabel),
              onTap: () {
                // إذا المستخدم زائر، نذهب إلى شاشة تسجيل الدخول
                context.pushNamed(RouteNames.login);
              },
            ),
            const Divider(),
          ],

          // Settings removed as requested
          ListTile(
            leading: const Icon(Icons.help),
            title: Text(AppStrings.helpLabel),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(AppStrings.aboutLabel),
            onTap: () {},
          ),

          if (appState.isUserLoggedIn) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorColor),
              title: Text(AppStrings.logoutLabel, style: const TextStyle(color: AppTheme.errorColor)),
              onTap: () async {
                final ok = await Notifications.showConfirm(context, AppStrings.logoutConfirm, confirmText: AppStrings.yes, cancelText: AppStrings.no);
                if (ok == true) {
                  await ref.read(appStateProvider.notifier).logoutUser();
                  if (context.mounted) context.go(AppConstants.welcomeRoute);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

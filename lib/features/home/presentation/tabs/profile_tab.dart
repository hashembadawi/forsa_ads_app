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
          // بطاقة الحساب المحسنة
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // صورة البروفايل على اليمين
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // دائرة الخلفية المضيئة
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // صورة البروفايل
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Icon(
                            Icons.person_rounded,
                            size: 32,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      // أيقونة التعديل
                      if (appState.isUserLoggedIn)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 12,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // الفاصل العامودي
                  Container(
                    height: 60,
                    width: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // معلومات المستخدم على اليسار
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // اسم المستخدم
                        if (appState.isUserLoggedIn && 
                            (appState.userFirstName != null || appState.userLastName != null))
                          Text(
                            '${appState.userFirstName ?? ''} ${appState.userLastName ?? ''}'.trim(),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        
                        if (!appState.isUserLoggedIn)
                          Text(
                            AppStrings.guestLabel,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        
                        const SizedBox(height: 8),
                        
                        // رقم الهاتف
                        if (appState.isUserLoggedIn && appState.userPhone != null)
                          Row(
                            children: [
                              Icon(
                                Icons.phone_rounded,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                appState.userPhone!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        
                        const SizedBox(height: 8),
                        
                        // حالة الحساب
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: appState.isUserLoggedIn 
                                ? Colors.green.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: appState.isUserLoggedIn 
                                  ? Colors.green.withOpacity(0.5)
                                  : Colors.orange.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                appState.isUserLoggedIn 
                                    ? Icons.verified_rounded
                                    : Icons.person_outline_rounded,
                                size: 14,
                                color: appState.isUserLoggedIn ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                appState.isUserLoggedIn 
                                    ? AppStrings.registeredLabel
                                    : AppStrings.guestLabel,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: appState.isUserLoggedIn ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

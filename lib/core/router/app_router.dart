import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ui/app_keys.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/welcome/presentation/welcome_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/screens/edit_ad_screen.dart';
import '../../features/home/presentation/screens/ad_details_screen.dart';
import '../../features/home/data/models/ad_details.dart';
import '../../features/home/data/models/user_ad.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/auth_choice_screen.dart';
import '../../features/auth/presentation/verify_screen.dart';
import 'package:animations/animations.dart';
import '../utils/logger.dart';
import '../errors/error_handler.dart';

/// Router configuration with enhanced error handling and logging
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false, // Disable in production
    onException: (context, state, router) {
      final error = 'Navigation error: ${state.error}';
      logger.error(error, tag: 'ROUTER');
      ErrorHandler().handleError(state.error, null);
    },
    // إزالة redirect لمنع الحلقة اللا نهائية
    // التنقل سيتم التحكم فيه داخل الشاشات نفسها
    routes: [
        GoRoute(
          path: AppRoutes.splash,
          name: RouteNames.splash,
          pageBuilder: (context, state) {
            logger.debug('Building splash screen', tag: 'ROUTER');
            return _sharedTransitionPage(child: const SplashScreen(), key: state.pageKey);
          },
        ),
      GoRoute(
        path: AppRoutes.welcome,
        name: RouteNames.welcome,
        pageBuilder: (context, state) {
          logger.debug('Building welcome screen', tag: 'ROUTER');
          return _sharedTransitionPage(child: const WelcomeScreen(), key: state.pageKey);
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        name: RouteNames.home,
        pageBuilder: (context, state) {
          logger.debug('Building home screen', tag: 'ROUTER');
          final extra = state.extra;
          int? selectedTab;
          if (extra is Map && extra['selectedTab'] is int) selectedTab = extra['selectedTab'] as int;
          return _sharedTransitionPage(child: HomeScreen(initialIndex: selectedTab), key: state.pageKey);
        },
      ),
      GoRoute(
        path: AppRoutes.editAd,
        name: RouteNames.editAd,
        pageBuilder: (context, state) {
          logger.debug('Building edit ad screen', tag: 'ROUTER');
          final extra = state.extra;
          UserAd ad;
          List<dynamic> currencies = const [];
          if (extra is Map) {
            ad = extra['ad'] as UserAd;
            currencies = (extra['currencies'] as List?) ?? const [];
          } else {
            ad = extra as UserAd;
          }
          return _sharedTransitionPage(child: EditAdScreen(ad: ad, currencies: currencies), key: state.pageKey);
        },
      ),
      GoRoute(
        path: AppRoutes.adDetails,
        name: RouteNames.adDetails,
        pageBuilder: (context, state) {
          logger.debug('Building ad details screen', tag: 'ROUTER');
          final extra = state.extra;
          // Accept either AdDetails (preferred) or Map / UserAd fallback
          if (extra is AdDetails) {
            return _sharedTransitionPage(child: AdDetailsScreen(ad: extra), key: state.pageKey);
          } else if (extra is Map) {
            try {
              final adMap = Map<String, dynamic>.from(extra);
              final details = AdDetails.fromJson(adMap);
              return _sharedTransitionPage(child: AdDetailsScreen(ad: details), key: state.pageKey);
            } catch (_) {}
          } else if (extra is UserAd) {
            // Convert UserAd -> Map via its fields (best-effort minimal mapping)
            final map = {
              '_id': extra.id,
              'adTitle': extra.adTitle,
              'thumbnail': extra.thumbnail,
              'images': extra.images,
              'price': extra.price,
              'currencyName': extra.currencyName,
              'categoryName': extra.categoryName,
              'cityName': extra.cityName,
              'regionName': extra.regionName,
              'createDate': extra.createDate.toIso8601String(),
              'description': extra.description,
              'isApproved': extra.isApproved,
            };
            final details = AdDetails.fromJson(map);
            return _sharedTransitionPage(child: AdDetailsScreen(ad: details), key: state.pageKey);
          }

          throw Exception('Missing ad data for details screen');
        },
      ),
      GoRoute(
        path: AppRoutes.authChoice,
        name: RouteNames.authChoice,
        pageBuilder: (context, state) {
          logger.debug('Building auth choice screen', tag: 'ROUTER');
          return _sharedTransitionPage(child: const AuthChoiceScreen(), key: state.pageKey);
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        name: RouteNames.login,
        pageBuilder: (context, state) {
          logger.debug('Building login screen', tag: 'ROUTER');
          final extra = state.extra;
          int? returnTab;
          if (extra is Map && extra['returnTab'] is int) returnTab = extra['returnTab'] as int;
          return _sharedTransitionPage(child: AuthScreen(returnTab: returnTab), key: state.pageKey);
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        name: RouteNames.register,
        pageBuilder: (context, state) {
          logger.debug('Building register screen', tag: 'ROUTER');
          return _sharedTransitionPage(child: const RegisterScreen(), key: state.pageKey);
        },
      ),
          GoRoute(
            path: AppRoutes.verify,
            name: RouteNames.verify,
            pageBuilder: (context, state) {
              logger.debug('Building verify screen', tag: 'ROUTER');
              final extra = state.extra;
              String phone = '';
              String password = '';
              if (extra is Map) {
                phone = extra['phone'] ?? '';
                password = extra['password'] ?? '';
              }
              return _sharedTransitionPage(child: VerifyScreen(phoneNumber: phone, password: password), key: state.pageKey);
            },
          ),
    ],
  );
});

/// Helper that returns a CustomTransitionPage with the app-wide shared transition.
CustomTransitionPage<T> _sharedTransitionPage<T>({required Widget child, required LocalKey key}) {
  const duration = Duration(milliseconds: 320);
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: SharedAxisTransitionType.scaled,
        child: child,
      );
    },
  );
}

/// Enhanced route definitions with type safety
class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String home = '/home';
  static const String editAd = '/edit-ad';
  static const String adDetails = '/ad-details';
  static const String authChoice = '/auth-choice';
  static const String login = '/login';
  static const String register = '/register';
  static const String verify = '/verify';
  
  /// Get all available routes
  static List<String> get allRoutes => [splash, welcome, home, editAd, adDetails, authChoice, login, register];
  
  /// Validate if route exists
  static bool isValidRoute(String route) => allRoutes.contains(route);
}

/// Route names for type-safe navigation
class RouteNames {
  static const String splash = 'splash';
  static const String welcome = 'welcome';
  static const String home = 'home';
  static const String editAd = 'editAd';
  static const String adDetails = 'adDetails';
  static const String authChoice = 'authChoice';
  static const String login = 'login';
  static const String register = 'register';
  static const String verify = 'verify';
}

/// Navigation helper extensions
extension AppNavigationExtension on GoRouter {
  /// Navigate with logging
  void goNamed(String name, {Map<String, String> pathParameters = const {}}) {
    logger.userAction('Navigation', parameters: {'route': name, 'params': pathParameters});
    pushNamed(name, pathParameters: pathParameters);
  }
  
  /// Navigate with replacement and logging
  void goNamedReplacement(String name, {Map<String, String> pathParameters = const {}}) {
    logger.userAction('Navigation (Replace)', parameters: {'route': name, 'params': pathParameters});
    pushReplacementNamed(name, pathParameters: pathParameters);
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/providers/app_state_provider.dart';
import '../../../core/ui/notifications.dart';
import '../../../core/ui/app_keys.dart';
import '../../auth/data/services/auth_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializeApp();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      logger.info('Initializing app...', tag: 'SPLASH');
      
      // Load app state first
      await ref.read(appStateProvider.notifier).loadInitialState();
      
      // Check if user is logged in and validate token
      final appState = ref.read(appStateProvider);
      if (appState.isUserLoggedIn && appState.userToken != null) {
        logger.info('User logged in, validating token...', tag: 'SPLASH');
        await _validateToken(appState.userToken!);
      }
      
      // Wait for splash duration (2 seconds)
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        _navigateNext();
      }
    } catch (e) {
      logger.error('Error during app initialization', error: e, tag: 'SPLASH');
      // If there's an error, just navigate to welcome
      if (mounted) {
        context.go(AppRoutes.welcome);
      }
    }
  }

  Future<void> _validateToken(String token) async {
    try {
      final dio = Dio();
      final authService = AuthService(dio);
      
      final response = await authService.validateToken(token);
      final valid = response['valid'] as bool? ?? false;
      
      if (valid) {
        final userData = response['user'] as Map<String, dynamic>?;
        if (userData != null) {
          final isVerified = userData['isVerified'] as bool? ?? false;
          
          // اطبع رسالة وحيدة مطلوبة للمستخدم
          logger.info('الجلسة صالحة 200', tag: 'SPLASH');

          if (!isVerified) {
            // User not verified, show dialog after navigation
            logger.info('User not verified, will show dialog', tag: 'SPLASH');
            // Store flag to show dialog after navigation
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('_show_verify_dialog', true);
          }
          
          // Update user info in state
          await ref.read(appStateProvider.notifier).loginUser(
            token: token,
            phone: userData['phoneNumber'] as String? ?? '',
            firstName: userData['firstName'] as String?,
            lastName: userData['lastName'] as String?,
            profileImage: userData['profileImage'] as String?,
            accountNumber: userData['accountNumber'] as String?,
            userId: userData['userId'] as String?,
            isVerified: isVerified,
            isAdmin: userData['isAdmin'] as bool? ?? false,
            isSpecial: userData['isSpecial'] as bool? ?? false,
          );
          
          // تم التحقق بنجاح
        }
      } else {
        // Token invalid, logout user
        logger.info('Token invalid, logging out', tag: 'SPLASH');
        await ref.read(appStateProvider.notifier).logoutUser();
      }
    } catch (e) {
      logger.error('Failed to validate token', error: e, tag: 'SPLASH');
      // On error, keep user logged in but will need to revalidate later
    }
  }

  void _navigateNext() {
    try {
      final appState = ref.read(appStateProvider);
      
      logger.info('Navigating from splash: firstTime=${appState.isFirstTime}, loggedIn=${appState.isUserLoggedIn}, verified=${appState.isVerified}', tag: 'SPLASH');
      
      if (appState.isFirstTime) {
        logger.info('Navigating to welcome screen', tag: 'SPLASH');
        context.go(AppRoutes.welcome);
      } else if (appState.isUserLoggedIn) {
        if (appState.isVerified) {
          logger.info('Navigating to home screen', tag: 'SPLASH');
          context.go(AppRoutes.home);
          // Check if we need to show verify dialog
          _checkAndShowVerifyDialog();
        } else {
          logger.info('Navigating to home screen (not verified)', tag: 'SPLASH');
          context.go(AppRoutes.home);
          // Show verify dialog after navigation
          _checkAndShowVerifyDialog();
        }
      } else if (appState.isGuest) {
        logger.info('Navigating to home screen as guest', tag: 'SPLASH');
        context.go(AppRoutes.home);
      } else {
        logger.info('Navigating to welcome screen (default)', tag: 'SPLASH');
        context.go(AppRoutes.welcome);
      }
    } catch (e) {
      logger.error('Error during navigation from splash', error: e, tag: 'SPLASH');
      // Fallback to welcome screen
      context.go(AppRoutes.welcome);
    }
  }

  Future<void> _checkAndShowVerifyDialog() async {
    // Wait a bit for navigation to complete
    await Future.delayed(const Duration(milliseconds: 500));
    
    final prefs = await SharedPreferences.getInstance();
    final shouldShow = prefs.getBool('_show_verify_dialog') ?? false;
    
    if (shouldShow && mounted) {
      await prefs.remove('_show_verify_dialog');
      _showVerifyDialog();
    }
  }

  void _showVerifyDialog() {
    final appState = ref.read(appStateProvider);
    final scaffoldMessengerKey = appScaffoldMessengerKey;
    final currentContext = scaffoldMessengerKey.currentContext;
    
    if (currentContext == null) return;
    
    Notifications.showConfirm(
      currentContext,
      'المستخدم غير مفعل، هل تريد تفعيل الحساب الآن؟',
      confirmText: 'تفعيل الآن',
      cancelText: 'لاحقاً',
    ).then((confirmed) {
      if (confirmed == true) {
        // Navigate to verify screen
        final phone = appState.userPhone ?? '';
        context.go(
          AppRoutes.verify,
          extra: {
            'phone': phone,
            'password': '', // Password not available, user will need to enter it
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo/Icon
                    Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  size: 60,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              
              // App Name in Arabic
              Text(
                'فرصة',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              
              // App Name in English
              Text(
                'FORSA',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 40),
              
              // Loading Indicator
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/providers/app_state_provider.dart';

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

  void _navigateNext() {
    try {
      final appState = ref.read(appStateProvider);
      
      logger.info('Navigating from splash: firstTime=${appState.isFirstTime}, loggedIn=${appState.isUserLoggedIn}', tag: 'SPLASH');
      
      if (appState.isFirstTime) {
        logger.info('Navigating to welcome screen', tag: 'SPLASH');
        context.go(AppRoutes.welcome);
      } else if (appState.isUserLoggedIn) {
        logger.info('Navigating to home screen', tag: 'SPLASH');
        context.go(AppRoutes.home);
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
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
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              
              // App Name in English
              Text(
                'FORSA',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
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
                    Colors.white.withValues(alpha: 0.8),
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
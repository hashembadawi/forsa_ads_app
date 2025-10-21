import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/network_utils.dart';
import '../../../shared/providers/app_state_provider.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onBrowseAsGuest() async {
    // Check internet connectivity first (consistent with other auth flows)
    final ok = await NetworkUtils.ensureConnected(context);
    if (!ok) return;

    try {
      await ref.read(appStateProvider.notifier).browseAsGuest();
    } catch (e) {
      // ignore error but keep navigation to home to preserve user intent
    }

    if (!mounted) return;
    context.go(AppConstants.homeRoute);
  }

  void _onLoginRegister() {
    context.go(AppConstants.authRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 
                    MediaQuery.of(context).padding.top - 
                    MediaQuery.of(context).padding.bottom - 48, // 24*2 padding
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
              const SizedBox(height: 20),
              
              // Hero Image/Illustration
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Icon(
                  Icons.store_mall_directory_rounded,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 30),
              
              // App Name
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              
              // Tagline
              Text(
                AppConstants.appTagline,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              
              // Features List
              _buildFeaturesList(),
              
              const SizedBox(height: 30),
              
              // Buttons
              _buildButtons(),
              const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {'icon': Icons.search_rounded, 'text': 'تصفح آلاف الإعلانات'},
      {'icon': Icons.add_circle_outline_rounded, 'text': 'أنشئ إعلانك بسهولة'},
      {'icon': Icons.favorite_rounded, 'text': 'احفظ إعلاناتك المفضلة'},
      {'icon': Icons.chat_rounded, 'text': 'تواصل مع البائعين'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: features.asMap().entries.map((entry) {
          final index = entry.key;
          final feature = entry.value;
          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 100)),
            curve: Curves.easeOutBack,
            child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature['text'] as String,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        // Browse as Guest Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 100),
            child: OutlinedButton.icon(
              onPressed: _onBrowseAsGuest,
              icon: const Icon(Icons.visibility_rounded),
              label: const Text(
                'تصفح بدون تسجيل',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Login/Register Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 100),
            child: ElevatedButton.icon(
              onPressed: _onLoginRegister,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text(
                'تسجيل الدخول / إنشاء حساب',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Terms text
        Text(
          'بالمتابعة، فإنك توافق على شروط الاستخدام وسياسة الخصوصية',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/providers/app_state_provider.dart';
import '../../../shared/extensions/context_extensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/tajawal_text.dart';
import '../../../core/utils/network_utils.dart';

// ثوابت للشاشة
const double _paddingLarge = 24.0;
const double _paddingMedium = 16.0;
const double _radiusCircular = 20.0;
const double _radiusMedium = 12.0;
const double _iconXXLarge = 80.0;
const double _iconSmall = 16.0;
const int _animationNormal = 300;

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
      duration: const Duration(milliseconds: 800), // مدة محسنة للأداء
      vsync: this,
      lowerBound: 0.0,
      upperBound: 1.0,
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

    // تأخير قصير قبل بدء الأنيميشن
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleBrowseAsGuest() async {
    final ok = await NetworkUtils.ensureConnected(context);
    if (!ok) return;

    try {
      await ref.read(appStateProvider.notifier).browseAsGuest();
    } catch (_) {
      // ignore errors but continue to navigation
    }

    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  void _handleLoginRegister() {
    context.go(AppRoutes.authChoice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(_paddingLarge),
          child: _buildAnimatedContent(),
        ),
      ),
    );
  }

  Widget _buildAnimatedContent() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(
              _slideAnimation.value.dx * 30,
              _slideAnimation.value.dy * 30,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: context.screenHeight -
                    context.padding.top -
                    context.padding.bottom -
                    (_paddingLarge * 2),
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                SizedBox(height: context.spacing20),
                _HeroSection(),
                SizedBox(height: context.spacing32),
                _AppInfoSection(),
                SizedBox(height: context.spacing16),
                _FeaturesList(),
                SizedBox(height: context.spacing32),
                _ActionButtons(
                  onBrowseAsGuest: _handleBrowseAsGuest,
                  onLoginRegister: _handleLoginRegister,
                ),
                SizedBox(height: context.spacing20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: context.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_radiusCircular),
      ),
      child: const Icon(
        Icons.store_mall_directory_rounded,
        size: _iconXXLarge + 16,
        color: null, // Will use primary color from theme
      ),
    );
  }
}

class _AppInfoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TajawalText.headlineLarge(
          'فرصة',
          color: context.textPrimary,
        ),
        SizedBox(height: context.spacing16),
        TajawalText.bodyLarge(
          'أفضل منصة للإعلانات في سوريا',
          textAlign: TextAlign.center,
          color: context.textSecondary,
        ),
      ],
    );
  }
}

class _FeaturesList extends StatelessWidget {
  static const _features = [
    _FeatureData(
      icon: Icons.search_rounded,
      text: 'تصفح آلاف الإعلانات',
    ),
    _FeatureData(
      icon: Icons.add_circle_outline_rounded,
      text: 'أنشئ إعلانك بسهولة',
    ),
    _FeatureData(
      icon: Icons.favorite_rounded,
      text: 'احفظ إعلاناتك المفضلة',
    ),
    _FeatureData(
      icon: Icons.chat_rounded,
      text: 'تواصل مع البائعين',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_paddingMedium),
      decoration: BoxDecoration(
        color: context.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(_radiusMedium),
      ),
      child: Column(
        children: _features.asMap().entries.map((entry) {
          final index = entry.key;
          final feature = entry.value;
          return _FeatureItem(
            feature: feature,
            animationDelay: Duration(
              milliseconds: _animationNormal + (index * 100),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FeatureItem extends StatefulWidget {
  final _FeatureData feature;
  final Duration animationDelay;

  const _FeatureItem({
    required this.feature,
    required this.animationDelay,
  });

  @override
  State<_FeatureItem> createState() => _FeatureItemState();
}

class _FeatureItemState extends State<_FeatureItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: _animationNormal),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value.clamp(0.0, 1.0),
          child: Opacity(
            opacity: _animation.value.clamp(0.0, 1.0),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: context.spacing8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      widget.feature.icon,
                      color: context.primary,
                      size: _iconSmall + 2,
                    ),
                  ),
                  SizedBox(width: context.spacing12),
                  Expanded(
                    child: TajawalText(
                      widget.feature.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onBrowseAsGuest;
  final VoidCallback onLoginRegister;

  const _ActionButtons({
    required this.onBrowseAsGuest,
    required this.onLoginRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppButton.outlined(
          text: 'تصفح بدون تسجيل',
          icon: Icons.visibility_rounded,
          onPressed: onBrowseAsGuest,
          fullWidth: true,
          size: AppButtonSize.large,
        ),
        SizedBox(height: context.spacing16),
        AppButton(
          text: 'تسجيل الدخول / إنشاء حساب',
          icon: Icons.person_add_rounded,
          onPressed: onLoginRegister,
          fullWidth: true,
          size: AppButtonSize.large,
        ),
        SizedBox(height: context.spacing16),
        TajawalText.bodySmall(
          'بالمتابعة، فإنك توافق على شروط الاستخدام وسياسة الخصوصية',
          textAlign: TextAlign.center,
          color: context.textSecondary,
        ),
      ],
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String text;

  const _FeatureData({
    required this.icon,
    required this.text,
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/app_state_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/network_utils.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/tajawal_text.dart';

/// شاشة اختيار نوع الدخول - مشترك أو زائر
class AuthChoiceScreen extends ConsumerWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // Use a scrollable and height-constrained layout so the content
          // can scroll on small devices and doesn't overflow vertically.
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // Ensure the content tries to fill the viewport height so
                // vertical centering works, but allow scrolling when needed.
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical - 48,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    TajawalText.headlineMedium(
                      'مرحباً بك في فرصة',
                      textAlign: TextAlign.center,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),

                    const SizedBox(height: 16),

                    // Explanatory text
                    TajawalText.bodyLarge(
                      'اختر طريقة الدخول التي تناسبك',
                      textAlign: TextAlign.center,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),

                    const SizedBox(height: 32),

                    // Auth options
                    _buildAuthOptions(context, ref),

                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthOptions(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // خيار إنشاء حساب
        _AuthOptionCard(
          title: 'إنشاء حساب جديد',
          subtitle: 'استمتع بجميع المزايا',
          features: const [
            'إضافة إعلانات مجانية',
            'حفظ الإعلانات المفضلة', 
            'تتبع إعلاناتك',
            'رسائل مع المشترين',
          ],
          buttonText: 'إنشاء حساب',
          onPressed: () => context.pushNamed(RouteNames.register),
          isPrimary: true,
        ),
        const SizedBox(height: 16),

        // عرض رابط تسجيل الدخول أعلى قسم التصفح كزائر
        _buildLoginLink(context),
        const SizedBox(height: 8),

        const SizedBox(height: 8),

        // خيار الدخول كزائر
        _AuthOptionCard(
          title: 'تصفح كزائر',
          subtitle: 'استكشف الإعلانات بدون تسجيل',
          features: const [
            'تصفح جميع الإعلانات',
            'البحث والفلترة المتقدمة',
            'مشاهدة تفاصيل الإعلانات',
          ],
          buttonText: 'تصفح كزائر',
          onPressed: () => _continueAsGuest(context, ref),
          isPrimary: false,
        ),
      ],
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TajawalText.bodyMedium(
          'لديك حساب بالفعل؟ ',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        GestureDetector(
          onTap: () => context.pushNamed(RouteNames.login),
          child: TajawalText.bodyMedium(
            'تسجيل الدخول',
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Future<void> _continueAsGuest(BuildContext context, WidgetRef ref) async {
    // Check connectivity first
    final ok = await NetworkUtils.ensureConnected(context);
    if (!ok) return;

    // تعيين وضع التصفح كزائر ثم الانتقال للصفحة الرئيسية
    try {
      await ref.read(appStateProvider.notifier).browseAsGuest();
    } catch (_) {
      // ignore
    }
    if (!context.mounted) return;
    context.goNamed(RouteNames.home);
  }
}

/// بطاقة خيار المصادقة
class _AuthOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> features;
  final String buttonText;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _AuthOptionCard({
    required this.title,
    required this.subtitle,
    required this.features,
    required this.buttonText,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPrimary 
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
          : Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: isPrimary 
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان والوصف
          TajawalText(
            title,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          
          const SizedBox(height: 4),
          
          TajawalText.bodyMedium(
            subtitle,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          
          const SizedBox(height: 16),
          
          // قائمة المزايا
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: isPrimary 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TajawalText.bodySmall(
                    feature,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )),
          
          const SizedBox(height: 20),
          
          // زر الإجراء
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: buttonText,
              onPressed: onPressed,
              variant: isPrimary ? AppButtonVariant.filled : AppButtonVariant.outlined,
              size: AppButtonSize.large,
              fullWidth: true,
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/notifications.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../../../core/utils/network_utils.dart';
import 'dart:convert';
import 'edit_profile_screen.dart';
import 'help_screen.dart'; // استيراد شاشة المساعدة الجديدة


class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  String? _profileImageBase64;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imageData = prefs.getString('userProfileImage');
      if (mounted && imageData != null && imageData.isNotEmpty) {
        setState(() {
          _profileImageBase64 = imageData;
        });
      }
    } catch (e) {
      // ignore errors
    }
  }

  Future<void> _deleteAccount() async {
    try {
      // التحقق من الاتصال بالإنترنت
      final hasConnection = await NetworkUtils.ensureConnected(context);
      if (!hasConnection || !mounted) return;

      // الحصول على userId و token
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final token = prefs.getString('user_token');

      if (userId == null || token == null) {
        if (mounted) {
          Notifications.showError(context, 'لم يتم العثور على بيانات المستخدم');
        }
        return;
      }

      // عرض مؤشر التحميل
      if (mounted) {
        Notifications.showLoading(context, message: 'جاري حذف الحساب...');
      }

      // إرسال طلب الحذف
      final response = await http.delete(
        Uri.parse('https://sahbo-app-api.onrender.com/api/user/delete-account'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
        }),
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;

      // إخفاء مؤشر التحميل
      Notifications.hideLoading(context);

      if (response.statusCode == 200) {
        // نجح الحذف
        if (mounted) {
          Notifications.showSuccess(
            context,
            'تم حذف الحساب بنجاح',
            okText: 'موافق',
            onOk: () async {
              // تسجيل الخروج وحذف البيانات المحلية
              await ref.read(appStateProvider.notifier).logoutUser();
              if (context.mounted) {
                context.go(AppConstants.welcomeRoute);
              }
            },
          );
        }
      } else {
        // فشل الحذف
        if (mounted) {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? 'فشل حذف الحساب';
          Notifications.showError(context, errorMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        Notifications.hideLoading(context);
        Notifications.showError(context, 'حدث خطأ أثناء حذف الحساب. يرجى المحاولة لاحقاً');
      }
    }
  }

  void _showEditProfileDialog() async {
    // Navigate to edit profile screen
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
    
    // If update was successful, reload profile image
    if (result == true && mounted) {
      setState(() {
        _profileImageBase64 = null;
      });
      await _loadProfileImage();
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: Column(
                children: [
                  // أزرار التعديل والحذف (فقط للمستخدمين المسجلين)
                  if (appState.isUserLoggedIn)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // زر التعديل
                        InkWell(
                          onTap: () {
                            // الانتقال إلى شاشة تعديل الملف الشخصي
                            _showEditProfileDialog();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_rounded,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'تعديل',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // زر الحذف
                        InkWell(
                          onTap: () async {
                            final ok = await Notifications.showConfirm(
                              context,
                              'هل أنت متأكد من حذف الحساب؟ هذا الإجراء لا يمكن التراجع عنه وسيتم حذف جميع بياناتك نهائياً.',
                              confirmText: 'حذف الحساب',
                              cancelText: 'إلغاء',
                            );
                            if (ok == true) {
                              await _deleteAccount();
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.errorColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.delete_rounded,
                                  size: 16,
                                  color: AppTheme.errorColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'حذف',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.errorColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  
                  if (appState.isUserLoggedIn)
                    const SizedBox(height: 12),
                  
                  // محتوى البطاقة الأصلي
                  Row(
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
                          backgroundImage: _profileImageBase64 != null && _profileImageBase64!.isNotEmpty
                              ? MemoryImage(base64Decode(_profileImageBase64!))
                              : null,
                          child: _profileImageBase64 == null || _profileImageBase64!.isEmpty
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 32,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                )
                              : null,
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

          // إعدادات الحساب
          // تم إزالة قسم الإعدادات بناءً على الطلب
          ListTile(
            leading: const Icon(Icons.help),
            title: Text(AppStrings.helpLabel),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
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

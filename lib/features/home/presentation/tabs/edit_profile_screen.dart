import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/notifications.dart';
import '../../../../core/utils/network_utils.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../../../shared/widgets/app_button.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  String? _currentProfileImageBase64;
  String? _newProfileImageBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    try {
      final appState = ref.read(appStateProvider);
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _firstNameController.text = appState.userFirstName ?? '';
        _lastNameController.text = appState.userLastName ?? '';
        _currentProfileImageBase64 = prefs.getString('userProfileImage');
      });
    } catch (e) {
      // ignore errors
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (file == null) return;
      
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      if (mounted) {
        setState(() {
          _newProfileImageBase64 = base64Image;
        });
      }
    } catch (e) {
      if (mounted) {
        Notifications.showError(context, 'فشل اختيار الصورة');
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // التحقق من الاتصال بالإنترنت
      final hasConnection = await NetworkUtils.ensureConnected(context);
      if (!hasConnection || !mounted) return;

      setState(() {
        _isLoading = true;
      });

      // الحصول على البيانات المطلوبة
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final token = prefs.getString('user_token');

      if (userId == null || token == null) {
        if (mounted) {
          Notifications.showError(context, 'لم يتم العثور على بيانات المستخدم');
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // عرض مؤشر التحميل
      if (mounted) {
        Notifications.showLoading(context, message: 'جاري تحديث البيانات...');
      }

      // إرسال طلب التحديث
      final response = await http.put(
        Uri.parse('https://sahbo-app-api.onrender.com/api/user/update-info'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'profileImage': _newProfileImageBase64 ?? _currentProfileImageBase64 ?? '',
        }),
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;

      // إخفاء مؤشر التحميل
      Notifications.hideLoading(context);

      if (response.statusCode == 200) {
        // نجح التحديث
        // حفظ البيانات الجديدة محلياً
        await prefs.setString('userFirstName', _firstNameController.text.trim());
        await prefs.setString('userLastName', _lastNameController.text.trim());
        
        if (_newProfileImageBase64 != null) {
          await prefs.setString('userProfileImage', _newProfileImageBase64!);
        }

        // تحديث الحالة في Provider
        await ref.read(appStateProvider.notifier).updateUserInfo(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
        );

        if (mounted) {
          Notifications.showSuccess(
            context,
            'تم تحديث البيانات بنجاح',
            okText: 'موافق',
            onOk: () {
              if (context.mounted) {
                Navigator.pop(context, true); // العودة مع إشارة نجاح
              }
            },
          );
        }
      } else {
        // فشل التحديث
        if (mounted) {
          try {
            final errorData = jsonDecode(response.body);
            final errorMessage = errorData['message'] ?? 'فشل تحديث البيانات';
            Notifications.showError(context, errorMessage);
          } catch (e) {
            Notifications.showError(context, 'فشل تحديث البيانات');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Notifications.hideLoading(context);
        Notifications.showError(context, 'حدث خطأ أثناء التحديث. يرجى المحاولة لاحقاً');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayImage = _newProfileImageBase64 ?? _currentProfileImageBase64;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // صورة البروفايل
              Stack(
                alignment: Alignment.center,
                children: [
                  // دائرة الخلفية
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  
                  // الصورة
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 58,
                      backgroundColor: AppTheme.backgroundColor,
                      backgroundImage: displayImage != null && displayImage.isNotEmpty
                          ? MemoryImage(base64Decode(displayImage))
                          : null,
                      child: displayImage == null || displayImage.isEmpty
                          ? Icon(
                              Icons.person_rounded,
                              size: 60,
                              color: AppTheme.iconInactiveColor,
                            )
                          : null,
                    ),
                  ),

                  // زر تغيير الصورة
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentColor.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // نص توضيحي
              Text(
                'اضغط على الكاميرا لتغيير الصورة',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),

              const SizedBox(height: 40),

              // حقل الاسم الأول (نفس نمط الحقول في Step 2)
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم الأول',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال الاسم الأول';
                  }
                  if (value.trim().length < 2) {
                    return 'الاسم يجب أن يكون حرفين على الأقل';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // حقل الاسم الأخير (نفس نمط الحقول في Step 2)
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم الأخير',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال الاسم الأخير';
                  }
                  if (value.trim().length < 2) {
                    return 'الاسم يجب أن يكون حرفين على الأقل';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),

              // زر الحفظ (مطابق لأزرار التطبيق الأساسية: بدون أيقونة، النص في المنتصف)
              AppButton(
                text: 'حفظ التغييرات',
                onPressed: _isLoading ? null : _updateProfile,
                isLoading: _isLoading,
                size: AppButtonSize.large,
                fullWidth: true,
              ),

              const SizedBox(height: 16),

              // زر الإلغاء
              AppButton.outlined(
                text: 'إلغاء',
                onPressed: () => Navigator.pop(context),
                size: AppButtonSize.large,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

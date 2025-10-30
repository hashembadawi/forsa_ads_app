# تطبيق التحقق من صلاحية الجلسة عند بدء التشغيل

## نظرة عامة
تم تنفيذ نظام التحقق من صلاحية الجلسة (Token Validation) عند تشغيل التطبيق للتأكد من صلاحية بيانات المستخدم المسجل دخوله.

## الملفات المضافة

### 1. AuthService
**المسار:** `lib/features/auth/data/services/auth_service.dart`

خدمة جديدة للتعامل مع المصادقة والتحقق من صلاحية الجلسة:

```dart
class AuthService {
  Future<Map<String, dynamic>> validateToken(String token);
}
```

**نقطة النهاية:**
- URL: `http://localhost:10000/api/user/validate-token`
- Method: GET
- Headers: `Authorization: Bearer {token}`

**الاستجابة المتوقعة:**
```json
{
    "valid": true,
    "user": {
        "userId": "...",
        "phoneNumber": "...",
        "firstName": "...",
        "lastName": "...",
        "profileImage": "...",
        "accountNumber": "...",
        "isVerified": true/false,
        "isAdmin": true/false,
        "isSpecial": true/false
    }
}
```

## الملفات المحدّثة

### 1. AppState Model
**المسار:** `lib/shared/providers/app_state_provider.dart`

**الحقول المضافة:**
- `profileImage`: String? - صورة الملف الشخصي (base64)
- `accountNumber`: String? - رقم الحساب
- `isVerified`: bool - حالة التفعيل
- `isAdmin`: bool - المستخدم مدير
- `isSpecial`: bool - المستخدم مميز

**الدوال المحدثة:**

#### loginUser()
تم تحديثها لقبول المعلومات الإضافية:
```dart
Future<void> loginUser({
  required String token,
  required String phone,
  String? firstName,
  String? lastName,
  String? profileImage,
  String? accountNumber,
  String? userId,
  bool? isVerified,
  bool? isAdmin,
  bool? isSpecial,
});
```

#### updateUserInfo()
تم تحديثها لدعم الحقول الجديدة:
```dart
Future<void> updateUserInfo({
  String? firstName,
  String? lastName,
  String? profileImage,
  String? accountNumber,
  bool? isVerified,
  bool? isAdmin,
  bool? isSpecial,
});
```

#### logoutUser()
تم تحديثها لحذف جميع البيانات الجديدة عند تسجيل الخروج.

### 2. SplashScreen
**المسار:** `lib/features/splash/presentation/splash_screen.dart`

**التحسينات:**

#### 1. التحقق التلقائي من الجلسة
```dart
Future<void> _initializeApp() async {
  // تحميل حالة التطبيق
  await ref.read(appStateProvider.notifier).loadInitialState();
  
  // التحقق من صلاحية الجلسة إذا كان المستخدم مسجل دخول
  final appState = ref.read(appStateProvider);
  if (appState.isUserLoggedIn && appState.userToken != null) {
    await _validateToken(appState.userToken!);
  }
  
  // الانتقال للشاشة المناسبة
  _navigateNext();
}
```

#### 2. التحقق من الـ Token
```dart
Future<void> _validateToken(String token) async {
  final response = await authService.validateToken(token);
  final valid = response['valid'] as bool? ?? false;
  
  if (valid) {
    final userData = response['user'];
    final isVerified = userData['isVerified'] ?? false;
    
    // إذا كان المستخدم غير مفعل، نضع علامة لإظهار الحوار
    if (!isVerified) {
      await prefs.setBool('_show_verify_dialog', true);
    }
    
    // تحديث بيانات المستخدم
    await ref.read(appStateProvider.notifier).loginUser(...);
  } else {
    // الـ token غير صالح، تسجيل الخروج
    await ref.read(appStateProvider.notifier).logoutUser();
  }
}
```

#### 3. التنقل الذكي
```dart
void _navigateNext() {
  if (appState.isFirstTime) {
    // الذهاب لشاشة الترحيب
    context.go(AppRoutes.welcome);
  } else if (appState.isUserLoggedIn) {
    // الذهاب للشاشة الرئيسية
    context.go(AppRoutes.home);
    // فحص إذا كان يجب إظهار حوار التفعيل
    _checkAndShowVerifyDialog();
  } else if (appState.isGuest) {
    // الذهاب للشاشة الرئيسية كضيف
    context.go(AppRoutes.home);
  } else {
    // افتراضي: الذهاب لشاشة الترحيب
    context.go(AppRoutes.welcome);
  }
}
```

#### 4. حوار التفعيل
```dart
void _showVerifyDialog() {
  Notifications.showConfirm(
    context,
    'المستخدم غير مفعل، هل تريد تفعيل الحساب الآن؟',
    confirmText: 'تفعيل الآن',
    cancelText: 'لاحقاً',
  ).then((confirmed) {
    if (confirmed == true) {
      // الانتقال لشاشة التفعيل
      context.go(AppRoutes.verify, extra: {
        'phone': appState.userPhone ?? '',
        'password': '',
      });
    }
  });
}
```

## سيناريوهات الاستخدام

### السيناريو 1: مستخدم مفعّل
1. التطبيق يبدأ
2. تحميل حالة التطبيق من SharedPreferences
3. وجود token صالح
4. التحقق من Token عبر API
5. valid = true && isVerified = true
6. تحديث بيانات المستخدم
7. الانتقال للشاشة الرئيسية

### السيناريو 2: مستخدم غير مفعّل
1. التطبيق يبدأ
2. تحميل حالة التطبيق من SharedPreferences
3. وجود token صالح
4. التحقق من Token عبر API
5. valid = true && isVerified = false
6. تحديث بيانات المستخدم
7. الانتقال للشاشة الرئيسية
8. إظهار حوار "المستخدم غير مفعل، هل تريد تفعيل الحساب الآن؟"
9. إذا ضغط "تفعيل الآن" → الانتقال لشاشة التفعيل
10. إذا ضغط "لاحقاً" → البقاء في الشاشة الرئيسية

### السيناريو 3: Token غير صالح
1. التطبيق يبدأ
2. تحميل حالة التطبيق من SharedPreferences
3. وجود token
4. التحقق من Token عبر API
5. valid = false أو خطأ في الاتصال
6. تسجيل خروج المستخدم تلقائياً
7. الانتقال لشاشة الترحيب

### السيناريو 4: أول مرة
1. التطبيق يبدأ
2. لا توجد بيانات محفوظة
3. الانتقال لشاشة الترحيب

## التخزين المحلي (SharedPreferences)

### المفاتيح المستخدمة:
```dart
'is_first_time'          // bool
'is_user_logged_in'      // bool
'is_guest'               // bool
'user_token'             // String
'user_phone'             // String
'userFirstName'          // String
'userLastName'           // String
'userProfileImage'       // String (base64)
'userAccountNumber'      // String
'userIsVerified'         // bool
'userIsAdmin'            // bool
'userIsSpecial'          // bool
'userId'                 // String
'_show_verify_dialog'    // bool (temporary flag)
```

## معالجة الأخطاء

### خطأ في الاتصال بالشبكة
- يتم تسجيل الخطأ في Logger
- المستخدم يبقى مسجل دخول
- سيتم التحقق مرة أخرى في المرة القادمة

### خطأ في تحليل البيانات
- يتم تسجيل الخطأ في Logger
- الاحتفاظ بالحالة الحالية للمستخدم
- المستخدم يمكنه الاستمرار في استخدام التطبيق

### Token منتهي الصلاحية
- تسجيل خروج تلقائي
- حذف جميع البيانات المحفوظة
- الانتقال لشاشة الترحيب

## ملاحظات مهمة

### 1. عنوان API مختلف
نقطة نهاية التحقق من Token تستخدم عنواناً مختلفاً:
```dart
// في auth_service.dart
static const String baseUrl = 'http://localhost:10000';

// بينما بقية الـ APIs تستخدم:
static const String baseUrl = 'https://sahbo-app-api.onrender.com';
```

**ملاحظة:** تأكد من تحديث عنوان API في الإنتاج!

### 2. كلمة المرور غير متاحة
عند الانتقال لشاشة التفعيل من حوار التفعيل، كلمة المرور تكون فارغة لأنها غير محفوظة في التطبيق لأسباب أمنية. المستخدم سيحتاج لإدخالها مرة أخرى.

### 3. صورة الملف الشخصي
صورة الملف الشخصي يتم تخزينها كـ base64 string. تأكد من معالجتها بشكل صحيح في واجهة المستخدم.

## الاختبار

### اختبار السيناريوهات:

1. **مستخدم مفعّل:**
   ```json
   {
     "valid": true,
     "user": {
       "isVerified": true,
       ...
     }
   }
   ```
   ✅ يجب أن ينتقل مباشرة للشاشة الرئيسية

2. **مستخدم غير مفعّل:**
   ```json
   {
     "valid": true,
     "user": {
       "isVerified": false,
       ...
     }
   }
   ```
   ✅ يجب أن يظهر حوار التفعيل بعد الانتقال للشاشة الرئيسية

3. **Token غير صالح:**
   ```json
   {
     "valid": false
   }
   ```
   ✅ يجب تسجيل الخروج والانتقال لشاشة الترحيب

## التحسينات المستقبلية المقترحة

1. **إضافة Retry Logic** عند فشل الاتصال
2. **Cache للبيانات** لتحسين الأداء
3. **Background Token Refresh** لتجديد Token تلقائياً
4. **Biometric Authentication** للدخول السريع
5. **Token Expiration Handling** معالجة أفضل لانتهاء صلاحية Token

## الدعم والمساعدة

للمزيد من المعلومات أو الإبلاغ عن مشاكل، يرجى الاتصال بفريق التطوير.

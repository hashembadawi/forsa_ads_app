// Centralized UI strings for consistency and easy i18n migration
class AppStrings {
  // Generic
  static const ok = 'موافق';
  static const cancel = 'إلغاء';
  static const yes = 'نعم';
  static const no = 'لا';

  // Titles
  static const successTitle = 'نجاح';
  static const errorTitle = 'خطأ';
  static const confirmTitle = 'تأكيد';

  // Loading
  static const defaultLoading = 'جاري المعالجة...';

  // Network / auth
  static const networkError = 'حدث خطأ بالاتصال يرجى المحاولة لاحقاً';
  static const noInternet = 'لا يوجد اتصال بالإنترنت. يرجى التحقق والمحاولة لاحقاً';
  static const invalidCredentials = 'يرجى التأكد من رقم الهاتف أو كلمة المرور';
  static const genericError = 'حدث خطأ';
  
  // Image picker
  static const imagePickFailed = 'فشل اختيار الصورة';
  static const chooseImage = 'اختر صورة';
  static const removeImage = 'إزالة';
  
  // Home / Profile
  static const loginLabel = 'تسجيل الدخول';
  static const logoutLabel = 'تسجيل الخروج';
  static const logoutConfirm = 'هل متأكد أنك تريد تسجيل الخروج؟';
  static const guestLabel = 'زائر';
  static const registeredLabel = 'مستخدم مسجل';
  // Bottom navigation / tabs
  static const navHome = 'الرئيسية';
  static const navFavorites = 'المفضلة';
  static const navAddAd = 'إضافة إعلان';
  static const navMyAds = 'إعلاناتي';
  static const navProfile = 'حسابي';
  static const profileTitle = 'حسابي';
  // Auth prompts
  static const loginRequiredMessage = 'يجب تسجيل الدخول للوصول إلى هذه الصفحة. هل تريد تسجيل الدخول الآن؟';
  
  // Home screen texts
  static const welcomeRegistered = 'مرحباً بك في فرصة! 👋';
  static const welcomeGuest = 'أهلاً بك زائرنا الكريم! 👋';
  static const welcomeSubtitleRegistered = 'اكتشف أحدث الإعلانات أو أضف إعلانك الجديد';
  static const welcomeSubtitleGuest = 'تصفح الكثير من الإعلانات المتنوعة';
  static const categoriesTitle = 'الأقسام الرئيسية';
  static const recentAdsTitle = 'أحدث الإعلانات';

  // Category names
  static const categoryCars = 'سيارات';
  static const categoryRealEstate = 'عقارات';
  static const categoryElectronics = 'إلكترونيات';
  static const categoryFashion = 'أزياء';

  // Empty states
  static const favoritesEmpty = 'لا توجد إعلانات مفضلة بعد';
  static const addAdEmpty = 'إضافة إعلان جديد';
  static const myAdsEmpty = 'لم تضع أي إعلانات بعد';

  // Menu
  static const settingsLabel = 'الإعدادات';
  static const helpLabel = 'المساعدة';
  static const aboutLabel = 'حول التطبيق';
}

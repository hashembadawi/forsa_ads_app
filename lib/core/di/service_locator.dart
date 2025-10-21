import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';

/// Container للتبعيات المختلفة في التطبيق
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal() {
    _init();
  }

  final Map<Type, dynamic> _services = {};
  final Map<Type, dynamic> _singletons = {};

  /// تهيئة الخدمات
  void _init() {
    logger.info('Initializing Service Locator', tag: 'DI');
    
    // تسجيل الخدمات الأساسية
    _registerSingleton<AppLogger>(() => AppLogger());
    
    logger.info('Service Locator initialized successfully', tag: 'DI');
  }

  /// تسجيل خدمة كـ singleton
  void _registerSingleton<T>(T Function() factory) {
    _services[T] = factory;
    logger.debug('Registered singleton: ${T.toString()}', tag: 'DI');
  }

  /// تسجيل خدمة عادية
  void registerFactory<T>(T Function() factory) {
    _services[T] = factory;
    logger.debug('Registered factory: ${T.toString()}', tag: 'DI');
  }

  /// تسجيل instance محدد
  void registerInstance<T>(T instance) {
    _singletons[T] = instance;
    logger.debug('Registered instance: ${T.toString()}', tag: 'DI');
  }

  /// الحصول على خدمة
  T get<T>() {
    // التحقق من وجود instance
    if (_singletons.containsKey(T)) {
      return _singletons[T] as T;
    }

    // التحقق من وجود factory
    if (_services.containsKey(T)) {
      final factory = _services[T] as T Function();
      final instance = factory();
      
      // حفظ كـ singleton إذا لم يكن موجود
      if (!_singletons.containsKey(T)) {
        _singletons[T] = instance;
      }
      
      return instance;
    }

    logger.error('Service not found: ${T.toString()}', tag: 'DI');
    throw Exception('Service of type $T is not registered');
  }

  /// التحقق من وجود خدمة
  bool isRegistered<T>() {
    return _services.containsKey(T) || _singletons.containsKey(T);
  }

  /// إزالة تسجيل خدمة
  void unregister<T>() {
    _services.remove(T);
    _singletons.remove(T);
    logger.debug('Unregistered service: ${T.toString()}', tag: 'DI');
  }

  /// مسح جميع الخدمات
  void reset() {
    _services.clear();
    _singletons.clear();
    _init(); // إعادة تهيئة الخدمات الأساسية
    logger.info('Service Locator reset', tag: 'DI');
  }
}

/// مثيل عام للوصول السهل
final serviceLocator = ServiceLocator();

/// Providers للاستخدام مع Riverpod
final serviceLocatorProvider = Provider<ServiceLocator>((ref) => serviceLocator);

/// Provider للحصول على Logger
final loggerProvider = Provider<AppLogger>((ref) => serviceLocator.get<AppLogger>());

/// Extension لتسهيل الحصول على الخدمات
extension ServiceLocatorExtension on WidgetRef {
  T getService<T>() => read(serviceLocatorProvider).get<T>();
}

/// Mixin لتسهيل استخدام DI في الفئات
mixin ServiceLocatorMixin {
  T getService<T>() => serviceLocator.get<T>();
  AppLogger get logger => getService<AppLogger>();
}
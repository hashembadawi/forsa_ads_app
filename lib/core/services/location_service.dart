import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

class LocationService {
  /// التحقق من صلاحيات الموقع وطلبها إذا لزم الأمر
  Future<bool> checkAndRequestLocationPermission() async {
    try {
      // التحقق من حالة الصلاحية
      var status = await Permission.location.status;
      
      if (status.isDenied) {
        // طلب الصلاحية
        status = await Permission.location.request();
      }
      
      if (status.isPermanentlyDenied) {
        // فتح إعدادات التطبيق
        logger.warning('Location permission permanently denied', tag: 'LOCATION');
        await openAppSettings();
        return false;
      }
      
      return status.isGranted;
    } catch (e) {
      logger.error('Error checking location permission', error: e, tag: 'LOCATION');
      return false;
    }
  }

  /// التحقق من تفعيل خدمة الموقع
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      logger.error('Error checking location service', error: e, tag: 'LOCATION');
      return false;
    }
  }

  /// الحصول على الموقع الحالي
  Future<Position?> getCurrentLocation() async {
    try {
      // التحقق من الصلاحيات
      final hasPermission = await checkAndRequestLocationPermission();
      if (!hasPermission) {
        logger.warning('Location permission not granted', tag: 'LOCATION');
        return null;
      }

      // التحقق من تفعيل خدمة الموقع
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        logger.warning('Location service not enabled', tag: 'LOCATION');
        return null;
      }

      // الحصول على الموقع
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      logger.info('Location obtained: ${position.latitude}, ${position.longitude}', tag: 'LOCATION');
      return position;
    } catch (e) {
      logger.error('Error getting current location', error: e, tag: 'LOCATION');
      return null;
    }
  }

  /// فتح إعدادات الموقع
  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      logger.error('Error opening location settings', error: e, tag: 'LOCATION');
    }
  }
}

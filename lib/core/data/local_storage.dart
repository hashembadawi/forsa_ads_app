import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import 'base_repository.dart';
import 'result.dart';

/// خدمة التخزين المحلي باستخدام SharedPreferences
class LocalStorage implements LocalDataSource {
  static LocalStorage? _instance;
  SharedPreferences? _prefs;
  
  LocalStorage._();
  
  static Future<LocalStorage> getInstance() async {
    _instance ??= LocalStorage._();
    _instance!._prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  @override
  String get name => 'SharedPreferences';

  /// حفظ string
  Future<Result<void>> setString(String key, String value) async {
    try {
      final success = await _prefs!.setString(key, value);
      if (success) {
        logger.debug('Stored string: $key', tag: 'STORAGE');
        return const Result.success(null);
      } else {
        return Result.failure(Exception('Failed to store string'));
      }
    } catch (e) {
      logger.error('Error storing string', error: e, tag: 'STORAGE');
      return Result.failure(Exception('Storage error: $e'));
    }
  }

  /// الحصول على string
  Future<Result<String?>> getString(String key) async {
    try {
      final value = _prefs!.getString(key);
      logger.debug('Retrieved string: $key = ${value != null ? 'found' : 'null'}', tag: 'STORAGE');
      return Result.success(value);
    } catch (e) {
      logger.error('Error retrieving string', error: e, tag: 'STORAGE');
      return Result.failure(Exception('Storage error: $e'));
    }
  }

  /// حفظ int
  Future<Result<void>> setInt(String key, int value) async {
    try {
      final success = await _prefs!.setInt(key, value);
      if (success) {
        logger.debug('Stored int: $key = $value', tag: 'STORAGE');
        return const Result.success(null);
      } else {
        return Result.failure(Exception('Failed to store int'));
      }
    } catch (e) {
      logger.error('Error storing int', error: e, tag: 'STORAGE');
      return Result.failure(Exception('Storage error: $e'));
    }
  }

  /// الحصول على int
  Future<Result<int?>> getInt(String key) async {
    try {
      final value = _prefs!.getInt(key);
      logger.debug('Retrieved int: $key = $value', tag: 'STORAGE');
      return Result.success(value);
    } catch (e) {
      logger.error('Error retrieving int', error: e, tag: 'STORAGE');
      return Result.failure(Exception('Storage error: $e'));
    }
  }

  /// حفظ bool
  Future<Result<void>> setBool(String key, bool value) async {
    try {
      final success = await _prefs!.setBool(key, value);
      if (success) {
        logger.debug('Stored bool: $key = $value', tag: 'STORAGE');
        return const Result.success(null);
      } else {
        return Result.failure(Exception('Failed to store bool'));
      }
    } catch (e) {
      logger.error('Error storing bool', error: e, tag: 'STORAGE');
      return Result.failure(Exception('Storage error: $e'));
    }
  }

  /// الحصول على bool
  Future<Result<bool?>> getBool(String key) async {
    try {
      final value = _prefs!.getBool(key);
      logger.debug('Retrieved bool: $key = $value', tag: 'STORAGE');
      return Result.success(value);
    } catch (e) {
      logger.error('Error retrieving bool', error: e, tag: 'STORAGE');
      return Result.failure(Exception('Storage error: $e'));
    }
  }

  /// حفظ double
  Future<Result<void>> setDouble(String key, double value) async {
    try {
      final success = await _prefs!.setDouble(key, value);
      if (success) {
        logger.debug('Stored double: $key = $value', tag: 'STORAGE');
        return const Result.success(null);
      } else {
        return Result.failure(Exception('Failed to store double'));
      }
    } catch (e) {
      logger.error('Error storing double', error: e, tag: 'STORAGE');
      return Result.failure(Exception('Storage error: $e'));
    }
  }

  /// الحصول على double
  Future<Result<double?>> getDouble(String key) async {
    try {
      final value = _prefs!.getDouble(key);
      logger.debug('Retrieved double: $key = $value', tag: 'STORAGE');
      return Result.success(value);
    } catch (e) {
      logger.error('Error retrieving double', error: e, tag: 'STORAGE');
      return Result.failure(Exception('Storage error: $e'));
    }
  }

  /// حفظ List of String
  Future<Result<void>> setStringList(String key, List<String> value) async {
    try {
      final success = await _prefs!.setStringList(key, value);
      if (success) {
        logger.debug('Stored string list: $key (${value.length} items)', tag: 'STORAGE');
        return const Result.success(null);
      } else {
        return Result.failure(Exception('Failed to store string list'));
      }
    } catch (e) {
      logger.error('Error storing string list', error: e, tag: 'STORAGE');
      return Result.failure(Exception('Storage error: $e'));
    }
  }

  /// الحصول على List of String
  Future<Result<List<String>?>> getStringList(String key) async {
    try {
      final value = _prefs!.getStringList(key);
      logger.debug('Retrieved string list: $key (${value?.length ?? 0} items)', tag: 'STORAGE');
      return Result.success(value);
    } catch (e) {
      logger.error('Error retrieving string list', error: e, tag: 'STORAGE');
      return Result.failure(Exception('Storage error: $e'));
    }
  }

  /// حفظ كائن JSON
  Future<Result<void>> setJson(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      final result = await setString(key, jsonString);
      if (result.isSuccess) {
        logger.debug('Stored JSON: $key', tag: 'STORAGE');
      }
      return result;
    } catch (e) {
      logger.error('Error encoding JSON', error: e, tag: 'STORAGE');
      return Result.failure(Exception('JSON encoding error: $e'));
    }
  }

  /// الحصول على كائن JSON
  Future<Result<Map<String, dynamic>?>> getJson(String key) async {
    try {
      final result = await getString(key);
      if (result.isSuccess && result.data != null) {
        final decoded = jsonDecode(result.data!);
        logger.debug('Retrieved JSON: $key', tag: 'STORAGE');
        return Result.success(decoded as Map<String, dynamic>);
      } else {
        return const Result.success(null);
      }
    } catch (e) {
      logger.error('Error decoding JSON', error: e, tag: 'STORAGE');
      return Result.failure(Exception('JSON decoding error: $e'));
    }
  }

  /// حفظ قائمة من كائنات JSON
  Future<Result<void>> setJsonList(String key, List<Map<String, dynamic>> value) async {
    try {
      final jsonString = jsonEncode(value);
      final result = await setString(key, jsonString);
      if (result.isSuccess) {
        logger.debug('Stored JSON list: $key (${value.length} items)', tag: 'STORAGE');
      }
      return result;
    } catch (e) {
      logger.error('Error encoding JSON list', error: e, tag: 'STORAGE');
      return Result.failure(Exception('JSON list encoding error: $e'));
    }
  }

  /// الحصول على قائمة من كائنات JSON
  Future<Result<List<Map<String, dynamic>>?>> getJsonList(String key) async {
    try {
      final result = await getString(key);
      if (result.isSuccess && result.data != null) {
        final decoded = jsonDecode(result.data!);
        if (decoded is List) {
          final jsonList = decoded.cast<Map<String, dynamic>>();
          logger.debug('Retrieved JSON list: $key (${jsonList.length} items)', tag: 'STORAGE');
          return Result.success(jsonList);
        } else {
          return Result.failure(Exception('Stored data is not a list'));
        }
      } else {
        return const Result.success(null);
      }
    } catch (e) {
      logger.error('Error decoding JSON list', error: e, tag: 'STORAGE');
      return Result.failure(Exception('JSON list decoding error: $e'));
    }
  }

  /// حذف مفتاح
  Future<Result<void>> remove(String key) async {
    try {
      final success = await _prefs!.remove(key);
      if (success) {
        logger.debug('Removed key: $key', tag: 'STORAGE');
        return const Result.success(null);
      } else {
        return Result.failure(Exception('Failed to remove key'));
      }
    } catch (e) {
      logger.error('Error removing key', error: e, tag: 'STORAGE');
      return Result.failure(Exception('Storage error: $e'));
    }
  }

  /// التحقق من وجود مفتاح
  Future<Result<bool>> containsKey(String key) async {
    try {
      final exists = _prefs!.containsKey(key);
      return Result.success(exists);
    } catch (e) {
      logger.error('Error checking key existence', error: e, tag: 'STORAGE');
      return Result.failure(Exception('Storage error: $e'));
    }
  }

  /// الحصول على جميع المفاتيح
  Future<Result<Set<String>>> getKeys() async {
    try {
      final keys = _prefs!.getKeys();
      logger.debug('Retrieved ${keys.length} keys', tag: 'STORAGE');
      return Result.success(keys);
    } catch (e) {
      logger.error('Error getting keys', error: e, tag: 'STORAGE');
      return Result.failure(Exception('Storage error: $e'));
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await _prefs!.clear();
      logger.info('Cleared all local storage', tag: 'STORAGE');
    } catch (e) {
      logger.error('Error clearing storage', error: e, tag: 'STORAGE');
      rethrow;
    }
  }

  @override
  Future<bool> hasData() async {
    try {
      return _prefs!.getKeys().isNotEmpty;
    } catch (e) {
      logger.error('Error checking if storage has data', error: e, tag: 'STORAGE');
      return false;
    }
  }

  @override
  Future<int> getDataSize() async {
    try {
      final keys = _prefs!.getKeys();
      return keys.length;
    } catch (e) {
      logger.error('Error getting storage size', error: e, tag: 'STORAGE');
      return 0;
    }
  }
}
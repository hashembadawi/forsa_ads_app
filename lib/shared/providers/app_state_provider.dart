import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/logger.dart';

// App State Model
class AppState {
  final bool isFirstTime;
  final bool isUserLoggedIn;
  final bool isGuest;
  final String? userToken;
  final String? userPhone;
  final String? userFirstName;
  final String? userLastName;

  AppState({
    required this.isFirstTime,
    required this.isUserLoggedIn,
    this.isGuest = false,
    this.userToken,
    this.userPhone,
    this.userFirstName,
    this.userLastName,
  });

  AppState copyWith({
    bool? isFirstTime,
    bool? isUserLoggedIn,
    bool? isGuest,
    String? userToken,
    String? userPhone,
    String? userFirstName,
    String? userLastName,
  }) {
    return AppState(
      isFirstTime: isFirstTime ?? this.isFirstTime,
      isUserLoggedIn: isUserLoggedIn ?? this.isUserLoggedIn,
      isGuest: isGuest ?? this.isGuest,
      userToken: userToken ?? this.userToken,
      userPhone: userPhone ?? this.userPhone,
      userFirstName: userFirstName ?? this.userFirstName,
      userLastName: userLastName ?? this.userLastName,
    );
  }
}

// Storage Keys
class _StorageKeys {
  static const String isFirstTime = 'is_first_time';
  static const String isUserLoggedIn = 'is_user_logged_in';
  static const String isGuest = 'is_guest';
  static const String userToken = 'user_token';
  static const String userPhone = 'user_phone';
  static const String userFirstName = 'userFirstName';
  static const String userLastName = 'userLastName';
}

// App State Notifier
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState(
    isFirstTime: true,
    isUserLoggedIn: false,
    isGuest: false,
  ));

  bool _initialized = false;

  Future<void> loadInitialState() async {
    if (_initialized) {
      // Already initialized in this app session - no-op
      logger.debug('AppState already initialized, skipping load', tag: 'APP_STATE');
      return;
    }
    try {
      logger.info('Loading initial app state...', tag: 'APP_STATE');
      
      final prefs = await SharedPreferences.getInstance();
      
      final isFirstTime = prefs.getBool(_StorageKeys.isFirstTime) ?? true;
      final isUserLoggedIn = prefs.getBool(_StorageKeys.isUserLoggedIn) ?? false;
      final isGuest = prefs.getBool(_StorageKeys.isGuest) ?? false;
      final userToken = prefs.getString(_StorageKeys.userToken);
      final userPhone = prefs.getString(_StorageKeys.userPhone);
  final userFirstName = prefs.getString(_StorageKeys.userFirstName);
  final userLastName = prefs.getString(_StorageKeys.userLastName);

      state = AppState(
        isFirstTime: isFirstTime,
        isUserLoggedIn: isUserLoggedIn,
        isGuest: isGuest,
        userToken: userToken,
        userPhone: userPhone,
        userFirstName: userFirstName,
        userLastName: userLastName,
      );

      _initialized = true;
      
      logger.info('App state loaded: firstTime=$isFirstTime, loggedIn=$isUserLoggedIn', tag: 'APP_STATE');
    } catch (e) {
      logger.error('Failed to load initial state', error: e, tag: 'APP_STATE');
      // Keep default state
    }
  }

  Future<void> setFirstTimeCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_StorageKeys.isFirstTime, false);
      
      state = state.copyWith(isFirstTime: false);
      logger.info('First time completed', tag: 'APP_STATE');
    } catch (e) {
      logger.error('Failed to set first time completed', error: e, tag: 'APP_STATE');
    }
  }

  Future<void> loginUser({required String token, required String phone, String? firstName, String? lastName}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_StorageKeys.isUserLoggedIn, true);
      // when user logs in, clear guest flag
      await prefs.setBool(_StorageKeys.isGuest, false);
      await prefs.setString(_StorageKeys.userToken, token);
      await prefs.setString(_StorageKeys.userPhone, phone);
      if (firstName != null) await prefs.setString(_StorageKeys.userFirstName, firstName);
      if (lastName != null) await prefs.setString(_StorageKeys.userLastName, lastName);
      
      state = state.copyWith(
        isUserLoggedIn: true,
        isGuest: false,
        userToken: token,
        userPhone: phone,
        userFirstName: firstName ?? state.userFirstName,
        userLastName: lastName ?? state.userLastName,
      );
      logger.info('User logged in', tag: 'APP_STATE');
    } catch (e) {
      logger.error('Failed to login user', error: e, tag: 'APP_STATE');
    }
  }

  Future<void> logoutUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_StorageKeys.isUserLoggedIn, false);
      await prefs.setBool(_StorageKeys.isGuest, false);
      await prefs.remove(_StorageKeys.userToken);
      await prefs.remove(_StorageKeys.userPhone);
      await prefs.remove(_StorageKeys.userFirstName);
      await prefs.remove(_StorageKeys.userLastName);
      // حذف صورة البروفايل أيضاً
      await prefs.remove('userProfileImage');
      await prefs.remove('userId');
      
      state = state.copyWith(
        isUserLoggedIn: false,
        isGuest: false,
        userToken: null,
        userPhone: null,
        userFirstName: null,
        userLastName: null,
      );
      logger.info('User logged out', tag: 'APP_STATE');
    } catch (e) {
      logger.error('Failed to logout user', error: e, tag: 'APP_STATE');
    }
  }

  Future<void> updateUserInfo({String? firstName, String? lastName}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Update only provided values
      if (firstName != null) {
        await prefs.setString(_StorageKeys.userFirstName, firstName);
      }
      if (lastName != null) {
        await prefs.setString(_StorageKeys.userLastName, lastName);
      }
      
      // Update state with new values (or keep existing if null)
      state = state.copyWith(
        userFirstName: firstName ?? state.userFirstName,
        userLastName: lastName ?? state.userLastName,
      );
      
      logger.info('User info updated', tag: 'APP_STATE');
    } catch (e) {
      logger.error('Failed to update user info', error: e, tag: 'APP_STATE');
    }
  }

  Future<void> browseAsGuest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await setFirstTimeCompleted();
      await prefs.setBool(_StorageKeys.isGuest, true);
      state = state.copyWith(isGuest: true);
      logger.info('Browsing as guest', tag: 'APP_STATE');
    } catch (e) {
      logger.error('Failed to set guest mode', error: e, tag: 'APP_STATE');
    }
  }
}

// Provider
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});
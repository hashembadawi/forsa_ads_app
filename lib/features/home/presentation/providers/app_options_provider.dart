import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/models/app_options.dart';
import '../../data/services/options_service.dart';

// Provider for Dio instance
final dioProvider = Provider<Dio>((ref) => Dio());

// Provider for OptionsService
final optionsServiceProvider = Provider<OptionsService>((ref) {
  final dio = ref.watch(dioProvider);
  return OptionsService(dio);
});

// State for app options
class AppOptionsState {
  final AppOptions? options;
  final bool isLoading;
  final String? error;

  AppOptionsState({
    this.options,
    this.isLoading = false,
    this.error,
  });

  AppOptionsState copyWith({
    AppOptions? options,
    bool? isLoading,
    String? error,
  }) {
    return AppOptionsState(
      options: options ?? this.options,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Notifier for managing app options state
class AppOptionsNotifier extends StateNotifier<AppOptionsState> {
  final OptionsService _service;

  AppOptionsNotifier(this._service) : super(AppOptionsState());

  Future<AppOptions?> fetchOptions() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final options = await _service.fetchOptions();
      state = state.copyWith(
        options: options,
        isLoading: false,
      );
      return options;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل تحميل الخيارات',
      );
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider for app options notifier
final appOptionsProvider =
    StateNotifierProvider<AppOptionsNotifier, AppOptionsState>((ref) {
  final service = ref.watch(optionsServiceProvider);
  return AppOptionsNotifier(service);
});

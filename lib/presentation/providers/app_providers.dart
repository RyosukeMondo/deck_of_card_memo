import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/app_state.dart';

// App state provider
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>(
  (ref) => AppStateNotifier(),
);

// User preferences provider
final userPreferencesProvider = StateNotifierProvider<UserPreferencesNotifier, UserPreferences>(
  (ref) => UserPreferencesNotifier(),
);

// Loading state provider
final loadingProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider.select((state) => state.isLoading));
});

// Error state provider
final errorProvider = Provider<String?>((ref) {
  return ref.watch(appStateProvider.select((state) => state.error));
});

// Current app mode provider
final appModeProvider = Provider<AppMode>((ref) {
  return ref.watch(appStateProvider.select((state) => state.mode));
});

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState(preferences: UserPreferences.defaults()));

  void setMode(AppMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void markAssetLoaded(String assetId) {
    final newMap = Map<String, bool>.from(state.deferredAssetsLoaded);
    newMap[assetId] = true;
    state = state.copyWith(deferredAssetsLoaded: newMap);
  }

  void markAssetUnloaded(String assetId) {
    final newMap = Map<String, bool>.from(state.deferredAssetsLoaded);
    newMap.remove(assetId);
    state = state.copyWith(deferredAssetsLoaded: newMap);
  }

  void updatePreferences(UserPreferences preferences) {
    state = state.copyWith(preferences: preferences);
  }

  bool isAssetLoaded(String assetId) {
    return state.deferredAssetsLoaded[assetId] ?? false;
  }
}

class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  UserPreferencesNotifier() : super(UserPreferences.defaults());

  void toggleHapticFeedback() {
    state = state.copyWith(enableHapticFeedback: !state.enableHapticFeedback);
  }

  void toggleSoundEffects() {
    state = state.copyWith(enableSoundEffects: !state.enableSoundEffects);
  }

  void setDefaultViewMode(ViewMode mode) {
    state = state.copyWith(defaultViewMode: mode);
  }

  void toggleAutoRotation() {
    state = state.copyWith(enableAutoRotation: !state.enableAutoRotation);
  }

  void setAnimationSpeed(double speed) {
    if (speed >= 0.5 && speed <= 2.0) {
      state = state.copyWith(animationSpeed: speed);
    }
  }

  void togglePerformanceMode() {
    state = state.copyWith(enablePerformanceMode: !state.enablePerformanceMode);
  }

  void updatePreferences(UserPreferences newPreferences) {
    state = newPreferences;
  }

  void resetToDefaults() {
    state = UserPreferences.defaults();
  }
}
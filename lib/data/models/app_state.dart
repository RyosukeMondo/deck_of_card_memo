enum AppMode { 
  cardViewer('Card Viewer'),
  quiz('Quiz Mode'),
  settings('Settings'),
  statistics('Statistics');

  const AppMode(this.displayName);
  
  final String displayName;
}

enum ViewMode { 
  image('2D Image'),
  model3d('3D Model');

  const ViewMode(this.displayName);
  
  final String displayName;
}

class UserPreferences {
  final bool enableHapticFeedback;
  final bool enableSoundEffects;
  final ViewMode defaultViewMode;
  final bool enableAutoRotation;
  final double animationSpeed;
  final bool enablePerformanceMode;

  const UserPreferences({
    this.enableHapticFeedback = true,
    this.enableSoundEffects = true,
    this.defaultViewMode = ViewMode.image,
    this.enableAutoRotation = false,
    this.animationSpeed = 1.0,
    this.enablePerformanceMode = false,
  });

  static UserPreferences defaults() => const UserPreferences();

  UserPreferences copyWith({
    bool? enableHapticFeedback,
    bool? enableSoundEffects,
    ViewMode? defaultViewMode,
    bool? enableAutoRotation,
    double? animationSpeed,
    bool? enablePerformanceMode,
  }) => UserPreferences(
    enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
    enableSoundEffects: enableSoundEffects ?? this.enableSoundEffects,
    defaultViewMode: defaultViewMode ?? this.defaultViewMode,
    enableAutoRotation: enableAutoRotation ?? this.enableAutoRotation,
    animationSpeed: animationSpeed ?? this.animationSpeed,
    enablePerformanceMode: enablePerformanceMode ?? this.enablePerformanceMode,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferences &&
          runtimeType == other.runtimeType &&
          enableHapticFeedback == other.enableHapticFeedback &&
          enableSoundEffects == other.enableSoundEffects &&
          defaultViewMode == other.defaultViewMode &&
          enableAutoRotation == other.enableAutoRotation &&
          animationSpeed == other.animationSpeed &&
          enablePerformanceMode == other.enablePerformanceMode;

  @override
  int get hashCode => Object.hash(
    enableHapticFeedback,
    enableSoundEffects,
    defaultViewMode,
    enableAutoRotation,
    animationSpeed,
    enablePerformanceMode,
  );
}

class AppState {
  final bool isLoading;
  final String? error;
  final AppMode mode;
  final UserPreferences preferences;
  final Map<String, bool> deferredAssetsLoaded;

  const AppState({
    this.isLoading = false,
    this.error,
    this.mode = AppMode.cardViewer,
    required this.preferences,
    this.deferredAssetsLoaded = const {},
  });

  AppState copyWith({
    bool? isLoading,
    String? error,
    AppMode? mode,
    UserPreferences? preferences,
    Map<String, bool>? deferredAssetsLoaded,
  }) => AppState(
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    mode: mode ?? this.mode,
    preferences: preferences ?? this.preferences,
    deferredAssetsLoaded: deferredAssetsLoaded ?? this.deferredAssetsLoaded,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          error == other.error &&
          mode == other.mode &&
          preferences == other.preferences &&
          deferredAssetsLoaded == other.deferredAssetsLoaded;

  @override
  int get hashCode => Object.hash(
    isLoading,
    error,
    mode,
    preferences,
    deferredAssetsLoaded,
  );
}
# Flutter Card Memorization App - System Architecture Design

## Executive Summary

This document presents a comprehensive system architecture for a Flutter-based card memorization application featuring 52 playing cards with both 2D images and interactive 3D GLB models, integrated quiz functionality, and optimized asset management.

## Core Requirements Analysis

### Functional Requirements
- **Card Display**: 52 playing cards with dual view modes (2D image ↔ 3D GLB model)
- **User Interactions**: Tap to toggle views, rotate 3D models, navigate between cards
- **Quiz Mode**: Interactive quiz with scoring and progress tracking
- **Card Management**: Random shuffle, sequential navigation, card selection

### Technical Challenges
1. **3D Graphics Rendering**: GLB model display with programmatic camera control
2. **Asset Management**: 104+ files (52 images + 52 GLB models) optimization
3. **Complex State Management**: Quiz logic, card navigation, UI state coordination
4. **Performance Optimization**: Minimize initial download size and runtime performance

## System Architecture

### Layered Architecture Pattern

```
┌─────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                    │
├─────────────────────────────────────────────────────────┤
│  UI Widgets  │  Screens  │  Components  │  Animations   │
│ ─────────────────────────────────────────────────────── │
│ • CardDisplayWidget    • MainScreen    • 3DViewer      │
│ • QuizInterface       • SettingsScreen • ImageViewer    │
│ • NavigationControls  • ResultsScreen  • GestureHandler │
└─────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────┐
│                   BUSINESS LOGIC LAYER                  │
├─────────────────────────────────────────────────────────┤
│    State Management (Riverpod)    │    Controllers      │
│ ─────────────────────────────────────────────────────── │
│ • CardNotifier          • QuizController               │
│ • QuizNotifier          • NavigationController         │
│ • ViewModeNotifier      • AnimationController          │
│ • ProgressNotifier      • GestureController            │
└─────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────┐
│                     DATA LAYER                         │
├─────────────────────────────────────────────────────────┤
│   Asset Management   │   Models   │   Services          │
│ ─────────────────────────────────────────────────────── │
│ • AssetLoader        • Card       • StorageService      │
│ • DeferredLoader     • Quiz       • PreferencesService  │
│ • CacheManager       • Progress   • AnalyticsService    │
└─────────────────────────────────────────────────────────┘
```

### Component Architecture Diagram

```
                    ┌─────────────────┐
                    │   Flutter App   │
                    │  (ProviderScope) │
                    └─────────┬───────┘
                              │
                    ┌─────────▼───────┐
                    │   MainScreen    │
                    └─────────┬───────┘
                              │
                ┌─────────────┼─────────────┐
                │             │             │
        ┌───────▼──────┐ ┌────▼─────┐ ┌────▼─────┐
        │ CardDisplay  │ │NavigationBar│ │QuizPanel │
        │   Widget     │ │            │ │         │
        └───────┬──────┘ └──────────┘ └──────────┘
                │
        ┌───────▼──────┐
        │ ViewToggler  │
        │(GestureDetector)│
        └───────┬──────┘
                │
       ┌────────┴────────┐
       │                 │
┌──────▼──────┐  ┌──────▼──────┐
│ ImageViewer │  │Flutter3D    │
│             │  │Viewer       │
└─────────────┘  └─────────────┘
```

## Core Components Specification

### 1. 3D Rendering System

**Package Selection**: `flutter_3d_controller`
- **Rationale**: Most comprehensive API with programmatic camera control
- **Core Features**: Animation control, texture switching, camera orbit control
- **Platform**: WebView embedding Google's `<model-viewer>` component

```dart
// 3D Controller Interface
class Card3DController {
  Flutter3DController controller = Flutter3DController();
  
  // Camera controls
  void setCameraOrbit(double theta, double phi, double radius);
  void setCameraTarget(double x, double y, double z);
  
  // Model controls
  void loadModel(String assetPath);
  void playAnimation(String animationName);
  void resetToDefault();
}
```

### 2. State Management Architecture

**Framework**: Riverpod
- **Provider Types**: 
  - `StateNotifierProvider` for complex state (Quiz, Cards)
  - `Provider` for computed values
  - `FutureProvider` for async operations

```dart
// State Structure
class AppState {
  int currentCardIndex;
  ViewMode viewMode; // IMAGE | MODEL_3D
  List<Card> cards;
  QuizState quizState;
  UserPreferences preferences;
}

// Key Providers
final cardNotifierProvider = StateNotifierProvider<CardNotifier, AppState>();
final quizNotifierProvider = StateNotifierProvider<QuizNotifier, QuizState>();
final currentCardProvider = Provider<Card>((ref) => /* computed */);
```

### 3. Asset Management System

**Directory Structure**:
```
assets/
├── cards/
│   ├── images/           # 52 PNG files (c1.png - sk.png)
│   │   ├── c1.png
│   │   ├── ...
│   │   └── sk.png
│   └── models/           # 52 GLB files (c1.glb - sk.glb)
│       ├── c1.glb
│       ├── ...
│       └── sk.glb
└── ui/
    ├── icons/
    └── backgrounds/
```

**pubspec.yaml Configuration**:
```yaml
flutter:
  assets:
    - assets/cards/images/
    - assets/cards/models/
    - assets/ui/
```

### 4. Deferred Loading Strategy

**Implementation**: Android/Web deferred components
- **Initial Bundle**: Images + app logic only (~5-10MB)
- **Deferred Components**: 3D models loaded on-demand (~20-50MB)
- **Loading Strategy**: Progressive loading with user feedback

```dart
// Deferred Loading Implementation
class DeferredAssetLoader {
  static Future<void> loadCardModel(String cardId) async {
    if (!_isModelLoaded(cardId)) {
      await _loadDeferredComponent('card_models_$cardId');
    }
  }
  
  static bool isModelAvailable(String cardId) {
    return _loadedModels.contains(cardId);
  }
}
```

## Data Models

### Card Model
```dart
class Card {
  final String id;              // 'c1', 'd2', 'h3', 'sk'
  final String name;            // 'Ace of Clubs'
  final Suit suit;             // CLUBS, DIAMONDS, HEARTS, SPADES
  final Rank rank;             // ACE, TWO, THREE, ..., KING
  final String imagePath;      // 'assets/cards/images/c1.png'
  final String modelPath;      // 'assets/cards/models/c1.glb'
  final bool isModelLoaded;    // Deferred loading status
}
```

### Quiz Model
```dart
class QuizState {
  final List<QuizQuestion> questions;
  final int currentQuestionIndex;
  final int correctAnswers;
  final int incorrectAnswers;
  final Duration elapsedTime;
  final QuizMode mode; // IDENTIFICATION, MEMORY, SEQUENCE
}

class QuizQuestion {
  final Card targetCard;
  final List<Card> options;
  final QuizType type; // MULTIPLE_CHOICE, TRUE_FALSE, INPUT
}
```

## User Interface Specifications

### Main Screen Layout
```
┌─────────────────────────────────────────┐
│              App Bar                    │
│    [Menu] Card Memory App    [Settings] │
├─────────────────────────────────────────┤
│                                         │
│           Card Display Area             │
│        (Image/3D Model Toggle)          │
│              [Tap Here]                 │
│                                         │
├─────────────────────────────────────────┤
│    [◀] [1/52] [Random] [Quiz] [▶]      │
├─────────────────────────────────────────┤
│   View: [2D Image] [3D Model]          │
└─────────────────────────────────────────┘
```

### Navigation Flow
```
Main Screen ──┬── Quiz Mode
              ├── Settings
              ├── Statistics
              └── Card Details
```

## Performance Optimization Strategy

### 1. Asset Optimization
- **Image Compression**: WebP format with quality optimization
- **3D Model Optimization**: LOD (Level of Detail) for GLB files
- **Texture Compression**: Platform-specific texture formats

### 2. Memory Management
- **Lazy Loading**: Load assets only when needed
- **Cache Management**: LRU cache for recently viewed cards
- **Memory Monitoring**: Automatic cleanup of unused assets

### 3. Rendering Optimization
- **Frame Rate**: Target 60fps for smooth interactions
- **GPU Utilization**: Efficient 3D rendering pipeline
- **Battery Optimization**: Reduce rendering when app inactive

## Security & Privacy

### Data Protection
- **Local Storage**: All user progress stored locally
- **No Network Calls**: Fully offline application
- **Privacy**: No personal data collection or transmission

### Asset Protection
- **Bundle Security**: Assets embedded in app bundle
- **Code Obfuscation**: Flutter code obfuscation enabled
- **Platform Security**: Leverage platform-specific security features

## Testing Strategy

### Unit Testing
- **State Management**: Riverpod provider testing
- **Business Logic**: Quiz logic and card navigation
- **Utilities**: Asset loading and caching functions

### Widget Testing
- **UI Components**: Card display widgets
- **Interactions**: Gesture handling and navigation
- **State Integration**: Provider-widget integration

### Integration Testing
- **User Flows**: Complete user journeys
- **Performance**: Frame rate and memory usage
- **Platform Testing**: iOS and Android specific features

## Deployment Architecture

### Build Optimization
```yaml
# android/app/build.gradle
android {
    buildTypes {
        release {
            shrinkResources true
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt')
        }
    }
}
```

### Platform Distribution
- **Android**: Google Play Store with App Bundles
- **iOS**: App Store with asset optimization
- **Web**: Progressive Web App with service worker

## Future Enhancement Roadmap

### Phase 1 Extensions
- **AR Integration**: flutter_3d_controller AR viewer support
- **Custom Themes**: Multiple visual themes for cards
- **Advanced Statistics**: Detailed progress analytics

### Phase 2 Features
- **Multiplayer Quiz**: Local multiplayer functionality
- **Custom Card Sets**: User-defined card collections
- **Accessibility**: Enhanced screen reader support

### Phase 3 Innovations
- **Machine Learning**: Adaptive quiz difficulty
- **Voice Recognition**: Audio-based interactions
- **Cloud Sync**: Optional cloud progress backup

## Implementation Checklist

### Foundation Setup
- [ ] Flutter project initialization
- [ ] Riverpod state management setup
- [ ] Asset directory structure
- [ ] Basic navigation framework

### Core Features
- [ ] Card model and data layer
- [ ] 2D image display functionality
- [ ] 3D model integration with flutter_3d_controller
- [ ] View toggle mechanism
- [ ] Navigation controls

### Advanced Features
- [ ] Quiz mode implementation
- [ ] Deferred loading system
- [ ] Performance optimization
- [ ] Testing suite
- [ ] Platform-specific builds

This architecture provides a scalable, maintainable foundation for the Flutter card memorization app while addressing all technical requirements and performance considerations outlined in the original technical report.
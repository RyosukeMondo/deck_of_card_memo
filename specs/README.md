# Card Memory App

A Flutter-based card memorization application featuring 52 playing cards with both 2D images and interactive 3D GLB models, integrated quiz functionality, and optimized asset management.

## Features

- **Dual View Modes**: Switch between 2D images and 3D GLB models for each card
- **Interactive 3D**: Full 3D model interaction with camera controls
- **Quiz System**: Multiple quiz modes (identification, memory, sequence, matching)
- **Smart Asset Loading**: Deferred loading system for optimal performance
- **Responsive Design**: Works across mobile, tablet, and web platforms

## Technical Architecture

- **Framework**: Flutter 3.16+ with Dart 3.2+
- **State Management**: Riverpod for reactive state management
- **3D Rendering**: flutter_3d_controller for WebGL-based 3D display
- **Navigation**: GoRouter for declarative routing
- **Storage**: SharedPreferences for user preferences

## Getting Started

### Prerequisites

- Flutter SDK 3.16.0 or higher
- Dart SDK 3.2.0 or higher
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd deck_of_card_memo
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── core/                 # Core utilities and constants
│   ├── constants/        # App constants and configurations
│   ├── themes/          # App themes and styling
│   └── utils/           # Utility functions and helpers
├── data/                # Data layer
│   ├── models/          # Data models (Card, Quiz, AppState)
│   ├── repositories/    # Data repositories
│   └── services/        # Data services and API clients
├── presentation/        # Presentation layer
│   ├── screens/         # Screen widgets
│   ├── widgets/         # Reusable UI components
│   └── providers/       # Riverpod providers
└── assets/             # Static assets
    ├── cards/          # Card assets
    │   ├── images/     # 2D card images (PNG/WebP)
    │   └── models/     # 3D card models (GLB)
    └── ui/             # UI assets (icons, backgrounds)
```

## Asset Requirements

- **Images**: 52 PNG/WebP files (512x768 recommended resolution)
- **3D Models**: 52 GLB files (optimized for mobile, <5K polygons each)
- **Total Size**: ~50-70MB (with deferred loading optimization)

## Performance Optimization

- **Deferred Loading**: 3D models loaded on-demand
- **Asset Caching**: Smart LRU cache for recently viewed cards
- **Performance Monitoring**: Built-in FPS and memory monitoring
- **Predictive Loading**: Preloads likely-to-be-viewed cards

## Testing

Run tests with:
```bash
flutter test                    # Unit and widget tests
flutter test integration_test/  # Integration tests
```

## Building for Release

```bash
# Android
flutter build appbundle

# iOS
flutter build ipa

# Web
flutter build web
```

## Contributing

1. Follow the established architecture patterns
2. Maintain >90% test coverage
3. Use conventional commit messages
4. Ensure all lints pass

## License

This project is licensed under the MIT License - see the LICENSE file for details.
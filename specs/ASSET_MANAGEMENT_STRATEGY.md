# Asset Management & Deferred Loading Strategy

## Overview

This document outlines the comprehensive asset management strategy for the Flutter card memorization app, addressing the challenge of efficiently handling 104+ assets (52 images + 52 GLB models) while minimizing initial download size and optimizing runtime performance.

## Asset Inventory Analysis

### Current Asset Requirements
```
Total Assets: 104+ files
├── Images: 52 files (~10-15MB total)
│   ├── Format: PNG/WebP
│   ├── Resolution: 512x768 (recommended)
│   └── Compression: 80-85% quality
├── 3D Models: 52 files (~40-60MB total)
│   ├── Format: GLB (GLTF Binary)
│   ├── Polygons: <5,000 per model (optimized)
│   └── Textures: 512x512 embedded
└── UI Assets: ~20 files (~2MB total)
    ├── Icons, backgrounds, UI elements
    └── App branding assets
```

### Size Impact Analysis
```
Without Optimization:     With Deferred Loading:
┌─────────────────────┐   ┌─────────────────────┐
│ Initial Download    │   │ Initial Download    │
│ ~50-75MB           │   │ ~10-15MB           │
│                    │   │                    │
│ • All images       │   │ • All images       │
│ • All 3D models    │   │ • Core app logic   │
│ • App logic        │   │ • UI assets        │
│ • UI assets        │   │                    │
└─────────────────────┘   │ On-Demand Download  │
                          │ ~40-60MB           │
                          │                    │
                          │ • 3D models (lazy) │
                          │ • Advanced features │
                          └─────────────────────┘
```

## Deferred Loading Architecture

### Component-Based Deferred Loading

#### Android Implementation
```yaml
# android/app/build.gradle
android {
    bundle {
        // Enable app bundle with dynamic delivery
        abi { enableSplit true }
        density { enableSplit true }
        language { enableSplit true }
    }
    
    dynamicFeatures = [":card_models", ":advanced_features"]
}
```

#### Deferred Component Structure
```
project/
├── app/                          # Main app module
├── card_models/                  # Deferred 3D models
│   ├── build.gradle
│   ├── assets/
│   │   └── models/
│   │       ├── c1.glb
│   │       ├── ...
│   │       └── sk.glb
│   └── lib/
│       └── card_models_loader.dart
└── advanced_features/            # Deferred features
    ├── build.gradle
    └── lib/
        ├── ar_viewer.dart
        └── advanced_analytics.dart
```

### Deferred Loading Service Implementation

#### Core Deferred Loader
```dart
// lib/services/deferred_asset_loader.dart
import 'package:flutter/services.dart';
import 'deferred_components.dart' deferred as components;

class DeferredAssetLoader {
  static final Map<String, bool> _loadedComponents = {};
  static final Map<String, CompleterWithProgress> _loadingComponents = {};
  
  // Load specific card model
  static Future<bool> loadCardModel(String cardId) async {
    final componentId = 'card_model_$cardId';
    
    if (_loadedComponents[componentId] == true) {
      return true; // Already loaded
    }
    
    if (_loadingComponents.containsKey(componentId)) {
      return _loadingComponents[componentId]!.future; // Currently loading
    }
    
    return _loadComponent(componentId);
  }
  
  // Load batch of models (for improved UX)
  static Future<List<bool>> loadCardModels(List<String> cardIds) async {
    return Future.wait(cardIds.map(loadCardModel));
  }
  
  // Ensure model is available before showing 3D view
  static Future<bool> ensureModelLoaded(String cardId) async {
    try {
      return await loadCardModel(cardId);
    } catch (e) {
      print('Failed to load model for card $cardId: $e');
      return false;
    }
  }
  
  // Private component loader
  static Future<bool> _loadComponent(String componentId) async {
    final completer = CompleterWithProgress();
    _loadingComponents[componentId] = completer;
    
    try {
      // Load the deferred library
      await components.loadLibrary();
      
      // Verify assets are accessible
      await _verifyComponentAssets(componentId);
      
      _loadedComponents[componentId] = true;
      completer.complete(true);
      
      return true;
    } catch (error) {
      _loadedComponents[componentId] = false;
      completer.complete(false);
      
      print('Component loading failed: $componentId - $error');
      return false;
    } finally {
      _loadingComponents.remove(componentId);
    }
  }
  
  static Future<void> _verifyComponentAssets(String componentId) async {
    // Verify that the expected assets are available
    final assetBundle = DefaultAssetBundle.of(
      NavigationService.navigatorKey.currentContext!
    );
    
    // Test load a known asset from the component
    try {
      await assetBundle.load('assets/models/c1.glb');
    } catch (e) {
      throw AssetLoadException('Component assets not available: $componentId');
    }
  }
  
  // Preload popular cards (analytics-driven)
  static Future<void> preloadPopularCards() async {
    final popularCards = ['c1', 'd1', 'h1', 's1']; // Aces
    await loadCardModels(popularCards);
  }
  
  // Cache management
  static void clearComponentCache() {
    _loadedComponents.clear();
    // Note: Cannot actually unload deferred components in Flutter
    // This just clears our tracking state
  }
  
  static bool isComponentLoaded(String componentId) {
    return _loadedComponents[componentId] == true;
  }
  
  static bool isCardModelLoaded(String cardId) {
    return isComponentLoaded('card_model_$cardId');
  }
}

class CompleterWithProgress {
  final Completer<bool> _completer = Completer<bool>();
  double _progress = 0.0;
  
  Future<bool> get future => _completer.future;
  double get progress => _progress;
  
  void updateProgress(double progress) {
    _progress = progress;
  }
  
  void complete(bool result) {
    _completer.complete(result);
  }
}

class AssetLoadException implements Exception {
  final String message;
  AssetLoadException(this.message);
  
  @override
  String toString() => 'AssetLoadException: $message';
}
```

#### Progressive Loading Strategy
```dart
// lib/services/progressive_loader.dart
class ProgressiveLoadingStrategy {
  static const Map<String, int> _cardPopularity = {
    // Based on typical card game usage patterns
    'c1': 10, 'd1': 10, 'h1': 10, 's1': 10, // Aces - highest priority
    'c13': 8, 'd13': 8, 'h13': 8, 's13': 8,  // Kings
    'c12': 7, 'd12': 7, 'h12': 7, 's12': 7,  // Queens
    'c11': 6, 'd11': 6, 'h11': 6, 's11': 6,  // Jacks
    // ... other cards with lower priorities
  };
  
  static Future<void> initiateBackgroundLoading() async {
    // Start loading high-priority cards in background
    final priorityCards = _getPriorityCards();
    
    // Load in batches to avoid overwhelming the system
    for (int i = 0; i < priorityCards.length; i += 3) {
      final batch = priorityCards.skip(i).take(3).toList();
      await DeferredAssetLoader.loadCardModels(batch);
      
      // Small delay between batches to maintain UI responsiveness
      await Future.delayed(Duration(milliseconds: 100));
    }
  }
  
  static List<String> _getPriorityCards() {
    final entries = _cardPopularity.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).toList();
  }
  
  // Predictive loading based on user navigation patterns
  static Future<void> predictiveLoad(String currentCardId) async {
    final nextLikelyCards = _predictNextCards(currentCardId);
    
    // Load next 2-3 likely cards in background
    for (final cardId in nextLikelyCards.take(3)) {
      DeferredAssetLoader.loadCardModel(cardId); // Fire and forget
    }
  }
  
  static List<String> _predictNextCards(String currentCardId) {
    // Simple prediction: adjacent cards in sequence
    final cardIndex = CardDataService.getCardIndex(currentCardId);
    return [
      CardDataService.getCardIdByIndex((cardIndex + 1) % 52),
      CardDataService.getCardIdByIndex((cardIndex + 2) % 52),
      CardDataService.getCardIdByIndex((cardIndex - 1 + 52) % 52),
    ];
  }
}
```

### Asset Optimization Pipeline

#### Image Optimization
```dart
// lib/services/image_optimizer.dart
class ImageOptimizationService {
  static Future<void> optimizeImages() async {
    // This would be run during build process
    
    final imageAssets = await _getImageAssets();
    
    for (final imagePath in imageAssets) {
      await _optimizeImage(imagePath);
    }
  }
  
  static Future<void> _optimizeImage(String imagePath) async {
    // Convert to WebP if supported by platform
    if (await _isWebPSupported()) {
      await _convertToWebP(imagePath);
    }
    
    // Apply compression
    await _compressImage(imagePath, quality: 85);
    
    // Generate multiple resolutions for different screen densities
    await _generateDensityVariants(imagePath);
  }
  
  static Future<bool> _isWebPSupported() async {
    // Check platform support for WebP
    return Platform.isAndroid || kIsWeb;
  }
  
  static Future<void> _convertToWebP(String imagePath) async {
    // Implementation would use image processing library
    // like 'image' package or native platform tools
  }
  
  static Future<void> _compressImage(String imagePath, {required int quality}) async {
    // Compress image while maintaining visual quality
  }
  
  static Future<void> _generateDensityVariants(String imagePath) async {
    // Generate @1x, @2x, @3x variants for different screen densities
  }
  
  static Future<List<String>> _getImageAssets() async {
    // Read pubspec.yaml and enumerate image assets
    return [];
  }
}
```

#### 3D Model Optimization
```dart
// lib/services/model_optimizer.dart
class Model3DOptimizationService {
  static const int MAX_POLYGONS = 5000;
  static const int TEXTURE_SIZE = 512;
  
  static Future<void> optimizeGLBModels() async {
    final modelAssets = await _getGLBAssets();
    
    for (final modelPath in modelAssets) {
      await _optimizeGLBModel(modelPath);
    }
  }
  
  static Future<void> _optimizeGLBModel(String modelPath) async {
    // This would typically be done in the build pipeline
    // using external tools like gltf-pipeline or Blender scripts
    
    await _reducePolygonCount(modelPath, MAX_POLYGONS);
    await _optimizeTextures(modelPath, TEXTURE_SIZE);
    await _compressGLB(modelPath);
  }
  
  static Future<void> _reducePolygonCount(String modelPath, int maxPolygons) async {
    // Use Draco compression or mesh decimation
    print('Reducing polygon count for $modelPath to $maxPolygons');
  }
  
  static Future<void> _optimizeTextures(String modelPath, int textureSize) async {
    // Resize and compress textures embedded in GLB
    print('Optimizing textures in $modelPath to ${textureSize}x$textureSize');
  }
  
  static Future<void> _compressGLB(String modelPath) async {
    // Apply GLB compression techniques
    print('Compressing GLB model: $modelPath');
  }
  
  static Future<List<String>> _getGLBAssets() async {
    // Enumerate all GLB model assets
    return [];
  }
}
```

### Runtime Asset Management

#### Smart Caching System
```dart
// lib/services/asset_cache_manager.dart
class AssetCacheManager {
  static const int MAX_CACHE_SIZE_MB = 100;
  static const int MAX_CACHED_MODELS = 10;
  
  static final Map<String, CachedAsset> _cache = {};
  static int _currentCacheSize = 0;
  
  static Future<String> getAssetPath(String assetId, AssetType type) async {
    final cached = _cache[assetId];
    
    if (cached != null && await _isValidCachedAsset(cached)) {
      _updateAccessTime(assetId);
      return cached.localPath;
    }
    
    return await _loadAndCacheAsset(assetId, type);
  }
  
  static Future<String> _loadAndCacheAsset(String assetId, AssetType type) async {
    // Load asset (from deferred component or bundle)
    final assetData = await _loadAssetData(assetId, type);
    final localPath = await _storeAssetLocally(assetId, assetData);
    
    // Add to cache
    final cachedAsset = CachedAsset(
      id: assetId,
      localPath: localPath,
      size: assetData.lengthInBytes,
      accessTime: DateTime.now(),
      type: type,
    );
    
    _cache[assetId] = cachedAsset;
    _currentCacheSize += cachedAsset.size;
    
    // Enforce cache size limits
    await _enforceCache Limits();
    
    return localPath;
  }
  
  static Future<void> _enforceCacheLimits() async {
    if (_currentCacheSize > MAX_CACHE_SIZE_MB * 1024 * 1024 ||
        _cache.length > MAX_CACHED_MODELS) {
      await _evictLeastRecentlyUsed();
    }
  }
  
  static Future<void> _evictLeastRecentlyUsed() async {
    final sortedAssets = _cache.values.toList();
    sortedAssets.sort((a, b) => a.accessTime.compareTo(b.accessTime));
    
    // Remove oldest assets until within limits
    while ((_currentCacheSize > MAX_CACHE_SIZE_MB * 1024 * 1024 ||
            _cache.length > MAX_CACHED_MODELS) && 
           sortedAssets.isNotEmpty) {
      final assetToRemove = sortedAssets.removeAt(0);
      await _removeFromCache(assetToRemove.id);
    }
  }
  
  static Future<void> _removeFromCache(String assetId) async {
    final cached = _cache[assetId];
    if (cached != null) {
      await _deleteLocalFile(cached.localPath);
      _currentCacheSize -= cached.size;
      _cache.remove(assetId);
    }
  }
  
  static void _updateAccessTime(String assetId) {
    final cached = _cache[assetId];
    if (cached != null) {
      _cache[assetId] = cached.copyWith(accessTime: DateTime.now());
    }
  }
  
  // Cache warming for smooth UX
  static Future<void> warmCache(List<String> assetIds) async {
    for (final assetId in assetIds) {
      // Pre-load high-priority assets
      if (CardDataService.isHighPriorityCard(assetId)) {
        await getAssetPath(assetId, AssetType.model3d);
      }
    }
  }
  
  // Cleanup methods
  static Future<void> clearCache() async {
    for (final assetId in _cache.keys.toList()) {
      await _removeFromCache(assetId);
    }
  }
  
  static Future<void> cleanupExpiredAssets() async {
    final now = DateTime.now();
    final expiredAssets = _cache.entries
        .where((entry) => now.difference(entry.value.accessTime).inDays > 7)
        .map((entry) => entry.key)
        .toList();
    
    for (final assetId in expiredAssets) {
      await _removeFromCache(assetId);
    }
  }
  
  // Helper methods
  static Future<Uint8List> _loadAssetData(String assetId, AssetType type) async {
    switch (type) {
      case AssetType.image:
        return await rootBundle.load('assets/cards/images/$assetId.png');
      case AssetType.model3d:
        return await rootBundle.load('assets/cards/models/$assetId.glb');
      default:
        throw ArgumentError('Unsupported asset type: $type');
    }
  }
  
  static Future<String> _storeAssetLocally(String assetId, ByteData data) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$assetId');
    await file.writeAsBytes(data.buffer.asUint8List());
    return file.path;
  }
  
  static Future<bool> _isValidCachedAsset(CachedAsset cached) async {
    final file = File(cached.localPath);
    return await file.exists();
  }
  
  static Future<void> _deleteLocalFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

class CachedAsset {
  final String id;
  final String localPath;
  final int size;
  final DateTime accessTime;
  final AssetType type;
  
  const CachedAsset({
    required this.id,
    required this.localPath,
    required this.size,
    required this.accessTime,
    required this.type,
  });
  
  CachedAsset copyWith({
    String? id,
    String? localPath,
    int? size,
    DateTime? accessTime,
    AssetType? type,
  }) => CachedAsset(
    id: id ?? this.id,
    localPath: localPath ?? this.localPath,
    size: size ?? this.size,
    accessTime: accessTime ?? this.accessTime,
    type: type ?? this.type,
  );
}

enum AssetType { image, model3d, audio, other }
```

### Loading UX Components

#### Loading Progress Indicator
```dart
// lib/widgets/asset_loading_indicator.dart
class AssetLoadingIndicator extends StatelessWidget {
  final String assetId;
  final String message;
  final VoidCallback? onCancel;
  
  const AssetLoadingIndicator({
    Key? key,
    required this.assetId,
    this.message = 'Loading 3D model...',
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: _getLoadingProgress(assetId),
      initialData: 0.0,
      builder: (context, snapshot) {
        final progress = snapshot.data ?? 0.0;
        
        return Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                value: progress > 0 ? progress : null,
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (progress > 0) ...[
                SizedBox(height: 8),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (onCancel != null) ...[
                SizedBox(height: 16),
                TextButton(
                  onPressed: onCancel,
                  child: Text('Cancel'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
  
  Stream<double> _getLoadingProgress(String assetId) {
    // Return stream of loading progress
    // This would connect to the actual loading progress from DeferredAssetLoader
    return Stream.periodic(Duration(milliseconds: 100), (count) {
      return (count * 0.1).clamp(0.0, 1.0);
    }).take(10);
  }
}
```

## Performance Monitoring

### Asset Performance Metrics
```dart
// lib/services/asset_performance_monitor.dart
class AssetPerformanceMonitor {
  static final Map<String, AssetMetrics> _metrics = {};
  
  static void recordAssetLoad(
    String assetId,
    AssetType type,
    Duration loadTime,
    int assetSize,
  ) {
    _metrics[assetId] = AssetMetrics(
      assetId: assetId,
      type: type,
      loadTime: loadTime,
      assetSize: assetSize,
      loadCount: (_metrics[assetId]?.loadCount ?? 0) + 1,
      lastLoadTime: DateTime.now(),
    );
  }
  
  static AssetMetrics? getMetrics(String assetId) {
    return _metrics[assetId];
  }
  
  static List<AssetMetrics> getSlowLoadingAssets() {
    return _metrics.values
        .where((metric) => metric.loadTime.inMilliseconds > 3000)
        .toList();
  }
  
  static double getAverageLoadTime(AssetType type) {
    final typeMetrics = _metrics.values
        .where((metric) => metric.type == type)
        .toList();
    
    if (typeMetrics.isEmpty) return 0.0;
    
    final totalTime = typeMetrics
        .map((m) => m.loadTime.inMilliseconds)
        .reduce((a, b) => a + b);
    
    return totalTime / typeMetrics.length;
  }
  
  static void generatePerformanceReport() {
    print('=== Asset Performance Report ===');
    print('Average load times:');
    print('  Images: ${getAverageLoadTime(AssetType.image).toStringAsFixed(1)}ms');
    print('  3D Models: ${getAverageLoadTime(AssetType.model3d).toStringAsFixed(1)}ms');
    print('\nSlow loading assets:');
    
    final slowAssets = getSlowLoadingAssets();
    for (final asset in slowAssets) {
      print('  ${asset.assetId}: ${asset.loadTime.inMilliseconds}ms');
    }
  }
}

class AssetMetrics {
  final String assetId;
  final AssetType type;
  final Duration loadTime;
  final int assetSize;
  final int loadCount;
  final DateTime lastLoadTime;
  
  const AssetMetrics({
    required this.assetId,
    required this.type,
    required this.loadTime,
    required this.assetSize,
    required this.loadCount,
    required this.lastLoadTime,
  });
}
```

This comprehensive asset management strategy addresses the core challenge of handling 104+ assets efficiently while providing an optimal user experience through intelligent deferred loading, caching, and performance optimization.
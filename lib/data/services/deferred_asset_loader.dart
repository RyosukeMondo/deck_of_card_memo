import 'dart:async';
import 'package:flutter/services.dart';
import 'card_data_service.dart';

class DeferredAssetLoader {
  static final Map<String, bool> _loadedComponents = {};
  static final Map<String, Completer<bool>> _loadingComponents = {};
  static final Map<String, DateTime> _lastAccessTimes = {};

  // Load specific card model
  static Future<bool> loadCardModel(String cardId) async {
    final componentId = 'card_model_$cardId';

    if (_loadedComponents[componentId] == true) {
      _updateAccessTime(componentId);
      return true; // Already loaded
    }

    if (_loadingComponents.containsKey(componentId)) {
      return await _loadingComponents[componentId]!.future; // Currently loading
    }

    return await _loadComponent(componentId, cardId);
  }

  // Load batch of models (for improved UX)
  static Future<List<bool>> loadCardModels(List<String> cardIds) async {
    return await Future.wait(cardIds.map(loadCardModel));
  }

  // Ensure model is available before showing 3D view
  static Future<bool> ensureModelLoaded(String cardId) async {
    print('📦 [AssetLoader] Ensuring model loaded for card: $cardId');
    
    try {
      // First check if asset exists in bundle
      final assetPath = 'assets/cards/models/$cardId.glb';
      print('📦 [AssetLoader] Checking asset path: $assetPath');
      
      try {
        final byteData = await rootBundle.load(assetPath);
        print('📦 [AssetLoader] Asset found in bundle, size: ${byteData.lengthInBytes} bytes');
        
        // Asset exists in bundle, mark as loaded
        final componentId = 'card_model_$cardId';
        _loadedComponents[componentId] = true;
        _updateAccessTime(componentId);
        print('📦 [AssetLoader] Asset marked as loaded: $componentId');
        return true;
      } catch (e) {
        print('📦 [AssetLoader] Asset not found in bundle: $e');
        print('📦 [AssetLoader] Trying deferred loading...');
        // Asset doesn't exist in bundle, try deferred loading
        return await loadCardModel(cardId);
      }
    } catch (e) {
      print('📦 [AssetLoader] Failed to load model for card $cardId: $e');
      return false;
    }
  }

  // Private component loader
  static Future<bool> _loadComponent(String componentId, String cardId) async {
    final completer = Completer<bool>();
    _loadingComponents[componentId] = completer;

    try {
      // Simulate deferred loading delay (in real app, this would load actual deferred components)
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify assets are accessible
      final isAvailable = await _verifyComponentAssets(cardId);

      _loadedComponents[componentId] = isAvailable;
      _updateAccessTime(componentId);
      completer.complete(isAvailable);

      return isAvailable;
    } catch (error) {
      _loadedComponents[componentId] = false;
      completer.complete(false);

      print('Component loading failed: $componentId - $error');
      return false;
    } finally {
      _loadingComponents.remove(componentId);
    }
  }

  static Future<bool> _verifyComponentAssets(String cardId) async {
    try {
      // Check if the GLB file exists in assets
      final assetPath = 'assets/cards/models/$cardId.glb';
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      print('Asset verification failed for $cardId: $e');
      return false;
    }
  }

  // Preload popular cards (analytics-driven)
  static Future<void> preloadPopularCards() async {
    final popularCards = CardDataService.getPopularCardIds();

    // Load in batches of 3 to avoid overwhelming the system
    for (int i = 0; i < popularCards.length; i += 3) {
      final batch = popularCards.skip(i).take(3).toList();
      await loadCardModels(batch);

      // Small delay between batches to maintain UI responsiveness
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // Predictive loading based on user navigation patterns
  static Future<void> predictiveLoad(String currentCardId) async {
    final nextLikelyCards = CardDataService.getPredictiveCards(currentCardId);

    // Load next 2-3 likely cards in background (fire and forget)
    for (final cardId in nextLikelyCards.take(3)) {
      loadCardModel(cardId); // Don't await - background loading
    }
  }

  // Cache management
  static void clearComponentCache() {
    _loadedComponents.clear();
    _lastAccessTimes.clear();
    // Note: Cannot actually unload deferred components in Flutter
    // This just clears our tracking state
  }

  static bool isComponentLoaded(String componentId) {
    return _loadedComponents[componentId] == true;
  }

  static bool isCardModelLoaded(String cardId) {
    return isComponentLoaded('card_model_$cardId');
  }

  static void _updateAccessTime(String componentId) {
    _lastAccessTimes[componentId] = DateTime.now();
  }

  // Get loading progress for a specific card
  static double getLoadingProgress(String cardId) {
    final componentId = 'card_model_$cardId';

    if (_loadedComponents[componentId] == true) {
      return 1.0; // Fully loaded
    }

    if (_loadingComponents.containsKey(componentId)) {
      // Return simulated progress (in real app, this would track actual progress)
      final startTime = DateTime.now().subtract(const Duration(seconds: 2));
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      return (elapsed / 2000.0).clamp(0.0, 0.9); // Max 90% while loading
    }

    return 0.0; // Not started
  }

  // Memory management - clean up old assets
  static Future<void> cleanupOldAssets() async {
    final now = DateTime.now();
    final expiredAssets = <String>[];

    // Find assets not accessed in the last hour
    _lastAccessTimes.forEach((componentId, lastAccess) {
      if (now.difference(lastAccess).inHours > 1) {
        expiredAssets.add(componentId);
      }
    });

    // Clean up expired assets
    for (final assetId in expiredAssets) {
      _loadedComponents.remove(assetId);
      _lastAccessTimes.remove(assetId);
    }

    print('Cleaned up ${expiredAssets.length} expired assets');
  }

  // Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'loaded_components': _loadedComponents.length,
      'currently_loading': _loadingComponents.length,
      'cache_size': _lastAccessTimes.length,
      'popular_cards_loaded': CardDataService.getPopularCardIds()
          .where((cardId) => isCardModelLoaded(cardId))
          .length,
    };
  }
}

class AssetLoadException implements Exception {
  final String message;
  AssetLoadException(this.message);

  @override
  String toString() => 'AssetLoadException: $message';
}

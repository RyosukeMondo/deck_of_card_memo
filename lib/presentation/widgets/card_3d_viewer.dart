import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DefaultAssetBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import '../providers/app_providers.dart';
import '../providers/card_providers.dart';
import '../../data/models/app_state.dart';
import '../../data/services/deferred_asset_loader.dart';
import '../../core/themes/app_theme.dart';

class Card3DViewer extends ConsumerStatefulWidget {
  final String cardId;
  final bool enableInteraction;
  final VoidCallback? onModelLoaded;
  final VoidCallback? onLoadError;

  const Card3DViewer({
    super.key,
    required this.cardId,
    this.enableInteraction = true,
    this.onModelLoaded,
    this.onLoadError,
  });

  @override
  ConsumerState<Card3DViewer> createState() => _Card3DViewerState();
}

class _Card3DViewerState extends ConsumerState<Card3DViewer> {
  bool isModelLoaded = false;
  bool isLoading = false;
  bool hasError = false;
  String? currentModelPath;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void didUpdateWidget(Card3DViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cardId != widget.cardId) {
      _loadModel();
    }
  }

  Future<void> _loadModel() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        hasError = false;
        isModelLoaded = false;
      });
    }

    try {
      // Check if model is available or load it
      final isAvailable = await DeferredAssetLoader.ensureModelLoaded(widget.cardId);
      
      if (isAvailable && mounted) {
        final modelPath = 'assets/cards/models/${widget.cardId}.glb';
        currentModelPath = modelPath;
        
        // Additional validation: Check if asset can be loaded
        try {
          final assetBundle = DefaultAssetBundle.of(context);
          final byteData = await assetBundle.load(modelPath);
          final fileSize = byteData.lengthInBytes;
          
          if (fileSize == 0) {
            throw Exception('GLB file is empty');
          }
          
          // Check GLB header (first 4 bytes should be "glTF")
          final headerBytes = byteData.buffer.asUint8List(0, 4);
          final header = String.fromCharCodes(headerBytes);
          
          if (header != 'glTF') {
            throw Exception('Invalid GLB file format (header: "$header")');
          }
        } catch (assetError) {
          throw assetError;
        }
        
        setState(() {
          isLoading = false;
          isModelLoaded = true;
        });
        
        widget.onModelLoaded?.call();
        
        // Add a small delay to ensure the 3D viewer is rendered
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() => isModelLoaded = true);
          }
        });
      } else if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
        widget.onLoadError?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
        widget.onLoadError?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingIndicator();
    }
    
    if (hasError) {
      return _buildErrorState();
    }
    
    if (isModelLoaded && currentModelPath != null) {
      return _build3DViewer();
    }
    
    return _buildLoadingIndicator();
  }

  Widget _build3DViewer() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Colors.grey[300]!,
            Colors.grey[100]!,
          ],
        ),
        border: Border.all(color: Colors.red, width: 2), // Debug border
      ),
      child: Stack(
        children: [
          // Debug info overlay
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: EdgeInsets.all(8),
              color: Colors.black54,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🎯 3D VIEWER DEBUG', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('Path: $currentModelPath', style: TextStyle(color: Colors.white, fontSize: 10)),
                  Text('Platform: ${_getPlatformInfo()}', style: TextStyle(color: Colors.white, fontSize: 10)),
                ],
              ),
            ),
          ),
          
          // The actual 3D viewer
          Builder(
            builder: (context) {
              try {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Flutter3DViewer(
                      src: currentModelPath!,
                    ),
                  ),
                );
              } catch (e) {
                return Container(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error, size: 48, color: Colors.red),
                        SizedBox(height: 8),
                        Text('3D Viewer Error: $e'),
                        SizedBox(height: 8),
                        Text('Path: $currentModelPath', style: TextStyle(fontSize: 12)),
                        SizedBox(height: 8),
                        Text('Platform: ${_getPlatformInfo()}', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
          
          // Fallback test button
          Positioned(
            bottom: 10,
            right: 10,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  _showDebugInfo(context);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.bug_report, color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPlatformInfo() {
    if (kIsWeb) {
      return 'Web';
    } else if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    } else {
      return 'Desktop';
    }
  }

  void _showDebugInfo(BuildContext context) {
    final platform = _getPlatformInfo();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('3D Viewer Debug'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Card ID: ${widget.cardId}'),
            Text('Model Path: $currentModelPath'),
            Text('Is Loaded: $isModelLoaded'),
            Text('Has Error: $hasError'),
            Text('Is Loading: $isLoading'),
            SizedBox(height: 16),
            Text('Platform: $platform', style: TextStyle(fontWeight: FontWeight.bold)),
            if (platform == 'Android') ...[
              Text('- Uses WebView with ModelViewer'),
              Text('- Hardware acceleration enabled'),
              Text('- WebGL support required'),
            ] else if (platform == 'Web') ...[
              Text('- Uses model-viewer web component'),
              Text('- WebGL context required'),
            ] else ...[
              Text('- Platform-specific rendering'),
            ],
            Text('- GLB model format required'),
            SizedBox(height: 16),
            Text('Troubleshooting:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('1. Check Android Chrome DevTools'),
            Text('2. Verify GLB model integrity'),
            Text('3. Check WebView console logs'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Force reload the model
              _loadModel();
              Navigator.pop(context);
            },
            child: Text('Reload Model'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            SizedBox(height: 16),
            Text(
              'Loading 3D Model...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This may take a moment',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red.withOpacity(0.1),
            Colors.red.withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.threed_rotation,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              '3D Model Unavailable',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Card ID: ${widget.cardId}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadModel,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () {
                    // Switch back to 2D mode
                    ref.read(viewModeProvider.notifier).setMode(ViewMode.image);
                  },
                  icon: const Icon(Icons.image, size: 16),
                  label: const Text('Use 2D'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Controller disposal handled by the Flutter3DViewer widget
    super.dispose();
  }
}
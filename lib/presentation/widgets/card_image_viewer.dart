import 'package:flutter/material.dart';
import '../../data/models/card.dart' as card_model;
import '../../core/themes/app_theme.dart';

class CardImageViewer extends StatefulWidget {
  final card_model.Card card;
  final bool enableInteraction;
  final VoidCallback? onImageLoaded;
  final VoidCallback? onLoadError;

  const CardImageViewer({
    super.key,
    required this.card,
    this.enableInteraction = true,
    this.onImageLoaded,
    this.onLoadError,
  });

  @override
  State<CardImageViewer> createState() => _CardImageViewerState();
}

class _CardImageViewerState extends State<CardImageViewer>
    with SingleTickerProviderStateMixin {
  bool _isLoaded = false;
  bool _hasError = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppTheme.normalAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _onImageLoaded() {
    if (mounted) {
      setState(() {
        _isLoaded = true;
        _hasError = false;
      });
      _animationController.forward();
      widget.onImageLoaded?.call();
    }
  }

  void _onImageError() {
    if (mounted) {
      setState(() {
        _hasError = true;
        _isLoaded = false;
      });
      widget.onLoadError?.call();
    }
  }


  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          // Main image with pan/zoom - fill all available space
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: InteractiveViewer(
                transformationController: _transformationController,
                boundaryMargin: EdgeInsets.zero,
                minScale: 0.1,
                maxScale: 4.0,
                clipBehavior: Clip.none,
                panEnabled: widget.enableInteraction,
                scaleEnabled: widget.enableInteraction,
                child: _buildCardImage(),
              ),
            ),
          ),

          // Zoom controls
          if (widget.enableInteraction && _isLoaded && !_hasError)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildZoomButton(
                      icon: Icons.zoom_in,
                      onPressed: () {
                        final currentScale = _transformationController.value.getMaxScaleOnAxis();
                        final newScale = (currentScale * 1.5).clamp(0.1, 4.0);
                        _transformationController.value = Matrix4.identity()..scale(newScale);
                      },
                    ),
                    _buildZoomButton(
                      icon: Icons.zoom_out,
                      onPressed: () {
                        final currentScale = _transformationController.value.getMaxScaleOnAxis();
                        final newScale = (currentScale / 1.5).clamp(0.1, 4.0);
                        _transformationController.value = Matrix4.identity()..scale(newScale);
                      },
                    ),
                    _buildZoomButton(
                      icon: Icons.center_focus_strong,
                      onPressed: _resetZoom,
                    ),
                  ],
                ),
              ),
            ),

          // Loading indicator
          if (!_isLoaded && !_hasError)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading image...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

          // Error state
          if (_hasError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Image not available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.card.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _isLoaded = false;
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardImage() {
    return SizedBox.expand(child: _buildImageWithFallback());
  }

  Widget _buildImageWithFallback() {
    final basePath = widget.card.imagePath.replaceAll('.png', '');
    final possiblePaths = [
      widget.card.imagePath, // Original PNG path
      '$basePath.jpg',
      '$basePath.jpeg',
    ];

    return _ImageWithFallback(
      imagePaths: possiblePaths,
      onImageLoaded: _onImageLoaded,
      onAllImagesFailed: _onImageError,
    );
  }

  Widget _buildPlaceholderCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.card.rank.code,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppTheme.getSuitColor(widget.card.suit.code),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.card.suit.symbol,
            style: TextStyle(
              fontSize: 32,
              color: AppTheme.getSuitColor(widget.card.suit.code),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.card.displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}


class _ImageWithFallback extends StatefulWidget {
  final List<String> imagePaths;
  final VoidCallback onImageLoaded;
  final VoidCallback onAllImagesFailed;

  const _ImageWithFallback({
    required this.imagePaths,
    required this.onImageLoaded,
    required this.onAllImagesFailed,
  });

  @override
  State<_ImageWithFallback> createState() => _ImageWithFallbackState();
}

class _ImageWithFallbackState extends State<_ImageWithFallback> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (_currentImageIndex >= widget.imagePaths.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onAllImagesFailed();
      });
      return const SizedBox.shrink();
    }

    return Image.asset(
      widget.imagePaths[_currentImageIndex],
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        if (_currentImageIndex < widget.imagePaths.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _currentImageIndex++;
              });
            }
          });
          return const SizedBox.shrink();
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onAllImagesFailed();
          });
          return const SizedBox.shrink();
        }
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onImageLoaded();
          });
          return child;
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppTheme.normalAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[100]!,
            Colors.grey[50]!,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          _buildBackgroundPattern(),

          // Main image
          Center(
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: _buildCardImage(),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 240,
          maxHeight: 360,
        ),
        child: AspectRatio(
          aspectRatio: 2.5 / 3.5, // Standard playing card ratio
          child: Image.asset(
            widget.card.imagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to placeholder card
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _onImageError();
              });
              return _buildPlaceholderCard();
            },
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _onImageLoaded();
                });
                return child;
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ),
      ),
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

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: CustomPaint(
        painter: CardBackgroundPainter(
          color: Colors.grey.withOpacity(0.05),
        ),
      ),
    );
  }
}

class CardBackgroundPainter extends CustomPainter {
  final Color color;

  CardBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const spacing = 40.0;
    const radius = 2.0;

    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

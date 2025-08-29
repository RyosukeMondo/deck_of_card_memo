import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/app_state.dart';
import '../providers/card_providers.dart';
import '../providers/app_providers.dart';
import 'card_image_viewer.dart';
import 'card_3d_viewer.dart';
import 'view_mode_indicator.dart';
import '../../core/themes/app_theme.dart';

class CardDisplayWidget extends ConsumerWidget {
  const CardDisplayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(viewModeProvider);
    final currentCard = ref.watch(currentCardProvider);
    final isLoading = ref.watch(loadingProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Fill all available space; cropping is handled by the inner viewer if needed
        return GestureDetector(
          onTap: () => ref.read(viewModeProvider.notifier).toggleMode(),
          child: SizedBox.expand(
            child: Stack(
              children: [
                // Main content
                AnimatedSwitcher(
                  duration: AppTheme.normalAnimation,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.3, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      ),
                    );
                  },
                  child: Builder(
                    builder: (context) {
                      print(
                          '🃏 [CardDisplay] Building card view - Mode: $viewMode, Card: ${currentCard.id}');

                      if (viewMode == ViewMode.image) {
                        print(
                            '🃏 [CardDisplay] Creating CardImageViewer for ${currentCard.id}');
                        return CardImageViewer(
                          key: ValueKey('image_${currentCard.id}'),
                          card: currentCard,
                        );
                      } else {
                        print(
                            '🃏 [CardDisplay] Creating Card3DViewer for ${currentCard.id}');
                        return Card3DViewer(
                          key: ValueKey('3d_${currentCard.id}'),
                          cardId: currentCard.id,
                          onModelLoaded: () {
                            print(
                                '🃏 [CardDisplay] 3D Model loaded callback for ${currentCard.id}');
                          },
                          onLoadError: () {
                            print(
                                '🃏 [CardDisplay] 3D Model load error callback for ${currentCard.id}');
                          },
                        );
                      }
                    },
                  ),
                ),

                // Loading overlay
                if (isLoading)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // View mode indicator
                Positioned(
                  top: 12,
                  right: 12,
                  child: ViewModeIndicator(mode: viewMode),
                ),

                // Card info overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentCard.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              currentCard.suit.symbol,
                              style: TextStyle(
                                color: AppTheme.getSuitColor(
                                    currentCard.suit.code),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currentCard.rank.name,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Tap hint (only show when not loading)
                if (!isLoading)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: AnimatedOpacity(
                      opacity: 0.8,
                      duration: AppTheme.normalAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: AppTheme.smallRadius,
                        ),
                        child: const Text(
                          'Tap to switch',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

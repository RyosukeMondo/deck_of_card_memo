import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/card_providers.dart';
import '../providers/app_providers.dart';
import '../../data/models/app_state.dart';
import '../../core/themes/app_theme.dart';

class NavigationControls extends ConsumerWidget {
  const NavigationControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentCardIndexProvider);
    final navigationController = ref.watch(cardNavigationProvider);
    final shuffledCards = ref.watch(shuffledCardsProvider);
    final isShuffled = shuffledCards != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Previous button
            _CompactNavigationButton(
              onPressed: navigationController.previousCard,
              icon: Icons.chevron_left,
              backgroundColor: AppTheme.primaryColor,
            ),

            // Shuffle button
            _CompactNavigationButton(
              onPressed: isShuffled 
                  ? navigationController.resetShuffle
                  : () => _showShuffleDialog(context, ref),
              icon: isShuffled ? Icons.restore : Icons.shuffle,
              backgroundColor: isShuffled ? Colors.orange : Colors.blue,
            ),

            // Card counter
            _CompactCardCounter(
              currentIndex: currentIndex,
              isShuffled: isShuffled,
            ),

            // View toggle button
            _CompactNavigationButton(
              onPressed: navigationController.toggleView,
              icon: _getViewModeIcon(ref),
              backgroundColor: Colors.teal,
            ),

            // Quiz mode button
            _CompactNavigationButton(
              onPressed: () => _startQuizMode(context, ref),
              icon: Icons.quiz,
              backgroundColor: Colors.purple,
            ),

            // Next button
            _CompactNavigationButton(
              onPressed: navigationController.nextCard,
              icon: Icons.chevron_right,
              backgroundColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getViewModeIcon(WidgetRef ref) {
    final viewMode = ref.watch(viewModeProvider);
    return viewMode == ViewMode.image ? Icons.threed_rotation : Icons.image;
  }

  String _getViewModeLabel(WidgetRef ref) {
    final viewMode = ref.watch(viewModeProvider);
    return viewMode == ViewMode.image ? '3D' : '2D';
  }

  void _showShuffleDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shuffle, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Shuffle Cards'),
          ],
        ),
        content: const Text(
          'This will randomize the order of all cards. Your current position will be reset.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(cardNavigationProvider).shuffle();
              Navigator.pop(context);
              
              // Show confirmation snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Cards shuffled successfully!'),
                    ],
                  ),
                  backgroundColor: AppTheme.successColor,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Shuffle'),
          ),
        ],
      ),
    );
  }

  void _startQuizMode(BuildContext context, WidgetRef ref) {
    ref.read(appStateProvider.notifier).setMode(AppMode.quiz);
    // Navigate to quiz screen
    // This would typically use go_router or Navigator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.quiz, color: Colors.white),
            SizedBox(width: 8),
            Text('Quiz mode coming soon!'),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _CompactNavigationButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color backgroundColor;

  const _CompactNavigationButton({
    required this.onPressed,
    required this.icon,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
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
}


class _CompactCardCounter extends StatelessWidget {
  final int currentIndex;
  final bool isShuffled;

  const _CompactCardCounter({
    required this.currentIndex,
    required this.isShuffled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppTheme.primaryColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).cardColor,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${currentIndex + 1}/52',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          if (isShuffled) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'S',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
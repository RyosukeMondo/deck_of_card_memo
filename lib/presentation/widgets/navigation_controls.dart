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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main navigation row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Previous button
                _NavigationButton(
                  onPressed: navigationController.previousCard,
                  icon: Icons.chevron_left,
                  label: 'Previous',
                  backgroundColor: AppTheme.primaryColor,
                ),

                // Card counter
                _CardCounter(
                  currentIndex: currentIndex,
                  isShuffled: isShuffled,
                ),

                // Next button
                _NavigationButton(
                  onPressed: navigationController.nextCard,
                  icon: Icons.chevron_right,
                  label: 'Next',
                  backgroundColor: AppTheme.primaryColor,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Secondary controls row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Shuffle button
                _SecondaryButton(
                  onPressed: isShuffled 
                      ? navigationController.resetShuffle
                      : () => _showShuffleDialog(context, ref),
                  icon: isShuffled ? Icons.restore : Icons.shuffle,
                  label: isShuffled ? 'Reset' : 'Shuffle',
                  backgroundColor: isShuffled ? Colors.orange : Colors.blue,
                ),

                // Quiz mode button
                _SecondaryButton(
                  onPressed: () => _startQuizMode(context, ref),
                  icon: Icons.quiz,
                  label: 'Quiz',
                  backgroundColor: Colors.purple,
                ),

                // View toggle button
                _SecondaryButton(
                  onPressed: navigationController.toggleView,
                  icon: _getViewModeIcon(ref),
                  label: _getViewModeLabel(ref),
                  backgroundColor: Colors.teal,
                ),
              ],
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

class _NavigationButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;

  const _NavigationButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;

  const _SecondaryButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 1,
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
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CardCounter extends StatelessWidget {
  final int currentIndex;
  final bool isShuffled;

  const _CardCounter({
    required this.currentIndex,
    required this.isShuffled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.primaryColor,
              width: 2,
            ),
            borderRadius: AppTheme.buttonRadius,
            color: Theme.of(context).cardColor,
          ),
          child: Column(
            children: [
              Text(
                '${currentIndex + 1}/52',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              if (isShuffled) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'SHUFFLED',
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
        ),
        const SizedBox(height: 6),
        const Text(
          'Cards',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
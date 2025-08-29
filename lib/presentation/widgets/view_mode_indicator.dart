import 'package:flutter/material.dart';
import '../../data/models/app_state.dart';
import '../../core/themes/app_theme.dart';

class ViewModeIndicator extends StatelessWidget {
  final ViewMode mode;
  final bool showLabel;
  final double size;

  const ViewModeIndicator({
    super.key,
    required this.mode,
    this.showLabel = true,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedContainer(
      duration: AppTheme.fastAnimation,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withOpacity(0.9),
        borderRadius: AppTheme.smallRadius,
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: AppTheme.fastAnimation,
            child: Icon(
              mode == ViewMode.image ? Icons.image : Icons.threed_rotation,
              key: ValueKey(mode),
              size: size * 0.8,
              color: AppTheme.primaryColor,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: AppTheme.fastAnimation,
              child: Text(
                mode.displayName,
                key: ValueKey(mode),
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
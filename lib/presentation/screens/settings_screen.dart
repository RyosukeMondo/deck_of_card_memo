import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../../data/models/app_state.dart';
import '../../core/themes/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(userPreferencesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            onPressed: () => _showResetDialog(context, ref),
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to Defaults',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Display Settings
          _buildSectionHeader('Display Settings'),
          _buildSettingsTile(
            title: 'Default View Mode',
            subtitle: 'Choose the initial view mode for cards',
            child: SegmentedButton<ViewMode>(
              segments: const [
                ButtonSegment(
                  value: ViewMode.image,
                  icon: Icon(Icons.image),
                  label: Text('2D Image'),
                ),
                ButtonSegment(
                  value: ViewMode.model3d,
                  icon: Icon(Icons.threed_rotation),
                  label: Text('3D Model'),
                ),
              ],
              selected: {preferences.defaultViewMode},
              onSelectionChanged: (Set<ViewMode> selection) {
                ref.read(userPreferencesProvider.notifier)
                   .setDefaultViewMode(selection.first);
              },
            ),
          ),
          
          _buildSwitchTile(
            title: 'Auto Rotation',
            subtitle: 'Automatically rotate 3D models',
            value: preferences.enableAutoRotation,
            onChanged: () => ref.read(userPreferencesProvider.notifier)
                                     .toggleAutoRotation(),
            icon: Icons.threed_rotation,
          ),

          const SizedBox(height: 16),

          // Animation Settings
          _buildSectionHeader('Animation Settings'),
          _buildSettingsTile(
            title: 'Animation Speed',
            subtitle: 'Adjust the speed of animations and transitions',
            child: Column(
              children: [
                Slider(
                  value: preferences.animationSpeed,
                  min: 0.5,
                  max: 2.0,
                  divisions: 6,
                  label: '${preferences.animationSpeed.toStringAsFixed(1)}x',
                  onChanged: (value) => ref.read(userPreferencesProvider.notifier)
                                           .setAnimationSpeed(value),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Slow (0.5x)', style: Theme.of(context).textTheme.bodySmall),
                    Text('Fast (2.0x)', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Feedback Settings
          _buildSectionHeader('Feedback Settings'),
          _buildSwitchTile(
            title: 'Haptic Feedback',
            subtitle: 'Vibrate on interactions',
            value: preferences.enableHapticFeedback,
            onChanged: () => ref.read(userPreferencesProvider.notifier)
                                     .toggleHapticFeedback(),
            icon: Icons.vibration,
          ),

          _buildSwitchTile(
            title: 'Sound Effects',
            subtitle: 'Play sounds for interactions',
            value: preferences.enableSoundEffects,
            onChanged: () => ref.read(userPreferencesProvider.notifier)
                                     .toggleSoundEffects(),
            icon: Icons.volume_up,
          ),

          const SizedBox(height: 16),

          // Performance Settings
          _buildSectionHeader('Performance Settings'),
          _buildSwitchTile(
            title: 'Performance Mode',
            subtitle: 'Reduce visual effects to improve performance',
            value: preferences.enablePerformanceMode,
            onChanged: () => ref.read(userPreferencesProvider.notifier)
                                     .togglePerformanceMode(),
            icon: Icons.speed,
          ),

          const SizedBox(height: 24),

          // App Information
          _buildSectionHeader('About'),
          _buildInfoTile(
            title: 'Version',
            subtitle: '1.0.0',
            icon: Icons.info,
          ),
          _buildInfoTile(
            title: 'Total Cards',
            subtitle: '52 Playing Cards',
            icon: Icons.style,
          ),
          _buildActionTile(
            title: 'View Licenses',
            subtitle: 'Open source licenses',
            icon: Icons.description,
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Card Memory App',
              applicationVersion: '1.0.0',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required VoidCallback onChanged,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: (_) => onChanged(),
        secondary: Icon(icon, color: AppTheme.primaryColor),
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        leading: Icon(icon, color: AppTheme.primaryColor),
        enabled: false,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        leading: Icon(icon, color: AppTheme.primaryColor),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppTheme.warningColor),
            SizedBox(width: 8),
            Text('Reset Settings'),
          ],
        ),
        content: const Text(
          'This will reset all settings to their default values. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(userPreferencesProvider.notifier).resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Settings reset to defaults'),
                    ],
                  ),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
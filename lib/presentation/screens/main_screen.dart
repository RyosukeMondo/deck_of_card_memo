import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/card_providers.dart';
import '../providers/app_providers.dart';
import '../widgets/card_display_widget.dart';
import '../widgets/navigation_controls.dart';
import '../widgets/debug_3d_test.dart';
import '../../core/themes/app_theme.dart';
import '../../data/services/deferred_asset_loader.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _preloadAssets();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: AppTheme.normalAnimation,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
  }

  void _preloadAssets() {
    // Start preloading popular cards in the background
    Future.microtask(() {
      DeferredAssetLoader.preloadPopularCards();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentCard = ref.watch(currentCardProvider);
    final error = ref.watch(errorProvider);

    // Listen to card changes for predictive loading
    ref.listen<int>(currentCardIndexProvider, (previous, current) {
      if (previous != null && previous != current) {
        final currentCardId = ref.read(currentCardProvider).id;
        DeferredAssetLoader.predictiveLoad(currentCardId);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Memory App'),
        actions: [
          IconButton(
            onPressed: _showAppInfo,
            icon: const Icon(Icons.info_outline),
            tooltip: 'App Information',
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const Debug3DTest(),
              ),
            ),
            icon: const Icon(Icons.bug_report),
            tooltip: '3D Debug Test',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'statistics',
                child: Row(
                  children: [
                    Icon(Icons.analytics),
                    SizedBox(width: 8),
                    Text('Statistics'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cache_info',
                child: Row(
                  children: [
                    Icon(Icons.storage),
                    SizedBox(width: 8),
                    Text('Cache Info'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Error display
            if (error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: AppTheme.errorColor,
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref.read(appStateProvider.notifier).clearError(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

            // Main content area (no outer padding so the image can expand)
            Expanded(
              child: Column(
                children: [
                  // Current card display fills available space
                  Expanded(
                    child: Hero(
                      tag: 'card_display_${currentCard.id}',
                      child: const CardDisplayWidget(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Card information - compact version with padding only around this section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildCompactCardInfo(currentCard),
                  ),
                ],
              ),
            ),

            // Navigation controls
            const NavigationControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCardInfo(card) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppTheme.cardRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCompactInfoChip('Suit', card.suit.name),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                card.displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                card.suit.symbol,
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.getSuitColor(card.suit.code),
                ),
              ),
            ],
          ),
          _buildCompactInfoChip('Value', card.rank.value.toString()),
        ],
      ),
    );
  }

  Widget _buildCardInfo(card) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppTheme.cardRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                card.displayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                card.suit.symbol,
                style: TextStyle(
                  fontSize: 24,
                  color: AppTheme.getSuitColor(card.suit.code),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoChip('Suit', card.suit.name),
              _buildInfoChip('Rank', card.rank.name),
              _buildInfoChip('Value', card.rank.value.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Card Memory App'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A Flutter-based card memorization application featuring:'),
            SizedBox(height: 12),
            Text('• 52 playing cards with 2D and 3D views'),
            Text('• Interactive 3D models with camera controls'),
            Text('• Quiz modes for memory training'),
            Text('• Smart asset loading for performance'),
            SizedBox(height: 12),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'settings':
        _showComingSoon('Settings');
        break;
      case 'statistics':
        _showComingSoon('Statistics');
        break;
      case 'cache_info':
        _showCacheInfo();
        break;
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.construction, color: Colors.white),
            const SizedBox(width: 8),
            Text('$feature coming soon!'),
          ],
        ),
        backgroundColor: AppTheme.warningColor,
      ),
    );
  }

  void _showCacheInfo() {
    final stats = DeferredAssetLoader.getCacheStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.storage, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Cache Information'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Loaded Components', stats['loaded_components'].toString()),
            _buildStatRow('Currently Loading', stats['currently_loading'].toString()),
            _buildStatRow('Cache Size', stats['cache_size'].toString()),
            _buildStatRow('Popular Cards Loaded', stats['popular_cards_loaded'].toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              DeferredAssetLoader.clearComponentCache();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: const Text('Clear Cache'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
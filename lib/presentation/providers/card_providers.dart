import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/card.dart';
import '../../data/models/app_state.dart';
import '../../data/services/card_data_service.dart';

// Card data provider
final cardDataProvider = Provider<List<Card>>((ref) {
  return CardDataService.getAllCards();
});

// Current card index provider
final currentCardIndexProvider = StateNotifierProvider<CardIndexNotifier, int>(
  (ref) => CardIndexNotifier(),
);

// Current card computed provider
final currentCardProvider = Provider<Card>((ref) {
  final cards = ref.watch(cardDataProvider);
  final index = ref.watch(currentCardIndexProvider);
  return cards[index % cards.length];
});

// View mode provider
final viewModeProvider = StateNotifierProvider<ViewModeNotifier, ViewMode>(
  (ref) => ViewModeNotifier(),
);

// Card navigation provider
final cardNavigationProvider = Provider<CardNavigationController>((ref) {
  return CardNavigationController(ref);
});

// Shuffled cards provider
final shuffledCardsProvider = StateNotifierProvider<ShuffledCardsNotifier, List<Card>?>(
  (ref) => ShuffledCardsNotifier(ref),
);

class CardIndexNotifier extends StateNotifier<int> {
  CardIndexNotifier() : super(0);

  void nextCard() {
    state = (state + 1) % 52; // Wrap around at 52
  }

  void previousCard() {
    state = state > 0 ? state - 1 : 51; // Wrap to last card
  }

  void goToCard(int index) {
    if (index >= 0 && index < 52) {
      state = index;
    }
  }

  void shuffle() {
    // Reset to first card when shuffling
    state = 0;
  }
}

class ViewModeNotifier extends StateNotifier<ViewMode> {
  ViewModeNotifier() : super(ViewMode.image);

  void toggleMode() {
    final oldMode = state;
    state = state == ViewMode.image ? ViewMode.model3d : ViewMode.image;
    print('🔄 [ViewMode] Toggled from $oldMode to $state');
  }

  void setMode(ViewMode mode) {
    final oldMode = state;
    state = mode;
    print('🔄 [ViewMode] Set from $oldMode to $state');
  }
}

class ShuffledCardsNotifier extends StateNotifier<List<Card>?> {
  final Ref ref;
  
  ShuffledCardsNotifier(this.ref) : super(null);

  void shuffle() {
    final cards = ref.read(cardDataProvider);
    state = CardDataService.getShuffledCards();
    // Reset card index when shuffling
    ref.read(currentCardIndexProvider.notifier).shuffle();
  }

  void reset() {
    state = null;
    ref.read(currentCardIndexProvider.notifier).goToCard(0);
  }
}

class CardNavigationController {
  final Ref ref;

  CardNavigationController(this.ref);

  void nextCard() {
    ref.read(currentCardIndexProvider.notifier).nextCard();
  }

  void previousCard() {
    ref.read(currentCardIndexProvider.notifier).previousCard();
  }

  void goToCard(int index) {
    ref.read(currentCardIndexProvider.notifier).goToCard(index);
  }

  void shuffle() {
    ref.read(shuffledCardsProvider.notifier).shuffle();
  }

  void resetShuffle() {
    ref.read(shuffledCardsProvider.notifier).reset();
  }

  void toggleView() {
    ref.read(viewModeProvider.notifier).toggleMode();
  }

  Card getCurrentCard() {
    return ref.read(currentCardProvider);
  }

  int getCurrentIndex() {
    return ref.read(currentCardIndexProvider);
  }

  ViewMode getCurrentViewMode() {
    return ref.read(viewModeProvider);
  }
}
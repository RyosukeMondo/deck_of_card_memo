import 'dart:math' show Random;
import '../models/card.dart';
import 'card_name_service.dart';

class CardDataService {
  // Lazily initialized to ensure CSV names are loaded first (main.dart awaits load()).
  static List<Card>? _allCards;

  static List<Card> getAllCards() => List.unmodifiable(_cards);

  static Card getCardById(String id) {
    try {
      return _cards.firstWhere((card) => card.id == id);
    } catch (e) {
      throw ArgumentError('Card with id "$id" not found');
    }
  }

  static int getCardIndex(String cardId) {
    final index = _cards.indexWhere((card) => card.id == cardId);
    if (index == -1) {
      throw ArgumentError('Card with id "$cardId" not found');
    }
    return index;
  }

  static String getCardIdByIndex(int index) {
    if (index < 0 || index >= _cards.length) {
      throw ArgumentError('Index $index out of range');
    }
    return _cards[index].id;
  }

  static bool isHighPriorityCard(String cardId) {
    // Aces and face cards are considered high priority
    final card = getCardById(cardId);
    return card.rank == Rank.ace || 
           card.rank == Rank.jack || 
           card.rank == Rank.queen || 
           card.rank == Rank.king;
  }

  static List<Card> getCardsBySuit(Suit suit) {
    return _cards.where((card) => card.suit == suit).toList();
  }

  static List<Card> getCardsByRank(Rank rank) {
    return _cards.where((card) => card.rank == rank).toList();
  }

  static List<Card> getShuffledCards({int? seed}) {
    final cards = List<Card>.from(_cards);
    if (seed != null) {
      cards.shuffle(Random(seed));
    } else {
      cards.shuffle();
    }
    return cards;
  }

  /// Generate all 52 playing cards
  static List<Card> _generateAllCards() {
    final cards = <Card>[];
    
    for (final suit in Suit.values) {
      for (final rank in Rank.values) {
        final id = _generateCardId(suit, rank);
        final csvName = CardNameService.instance.tryGet(id);
        final card = Card(
          id: id,
          // Use CSV-provided name if available, fallback to default English label
          name: csvName ?? '${rank.name} of ${suit.name}',
          suit: suit,
          rank: rank,
          imagePath: 'assets/cards/images/$id.png',
          modelPath: 'assets/cards/models/$id.glb',
        );
        cards.add(card);
      }
    }
    
    return cards;
  }

  /// Generate card ID in format: c1, d2, h3, sk, etc.
  static String _generateCardId(Suit suit, Rank rank) {
    final suitCode = suit.code.toLowerCase();
    final rankCode = rank.code.toLowerCase();
    return '$suitCode$rankCode';
  }

  // Internal lazy getter to initialize cards on first access.
  static List<Card> get _cards {
    _allCards ??= _generateAllCards();
    return _allCards!;
  }

  /// Rebuild the card list from the current CSV data.
  static void refreshFromNames() {
    _allCards = _generateAllCards();
  }

  /// Get popular cards for preloading (based on common card game usage)
  static List<String> getPopularCardIds() {
    return [
      // Aces (highest priority)
      'ca', 'da', 'ha', 'sa',
      // Face cards
      'ck', 'dk', 'hk', 'sk', // Kings
      'cq', 'dq', 'hq', 'sq', // Queens
      'cj', 'dj', 'hj', 'sj', // Jacks
      // Popular number cards
      'c10', 'd10', 'h10', 's10', // Tens
    ];
  }

  /// Get next likely cards for predictive loading
  static List<String> getPredictiveCards(String currentCardId) {
    final currentIndex = getCardIndex(currentCardId);
    final predictiveCards = <String>[];
    
    // Add adjacent cards
    if (currentIndex > 0) {
      predictiveCards.add(getCardIdByIndex(currentIndex - 1));
    }
    if (currentIndex < _cards.length - 1) {
      predictiveCards.add(getCardIdByIndex(currentIndex + 1));
    }
    
    // Add cards 2 positions away
    if (currentIndex > 1) {
      predictiveCards.add(getCardIdByIndex(currentIndex - 2));
    }
    if (currentIndex < _cards.length - 2) {
      predictiveCards.add(getCardIdByIndex(currentIndex + 2));
    }
    
    return predictiveCards;
  }
}
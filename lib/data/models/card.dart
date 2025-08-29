enum Suit { 
  clubs('C', 'Clubs', '♣'), 
  diamonds('D', 'Diamonds', '♦'), 
  hearts('H', 'Hearts', '♥'), 
  spades('S', 'Spades', '♠');

  const Suit(this.code, this.name, this.symbol);
  
  final String code;
  final String name;
  final String symbol;
}

enum Rank {
  ace(1, 'A', 'Ace'),
  two(2, '2', 'Two'),
  three(3, '3', 'Three'),
  four(4, '4', 'Four'),
  five(5, '5', 'Five'),
  six(6, '6', 'Six'),
  seven(7, '7', 'Seven'),
  eight(8, '8', 'Eight'),
  nine(9, '9', 'Nine'),
  ten(10, '10', 'Ten'),
  jack(11, 'J', 'Jack'),
  queen(12, 'Q', 'Queen'),
  king(13, 'K', 'King');

  const Rank(this.value, this.code, this.name);
  
  final int value;
  final String code;
  final String name;
}

class Card {
  final String id;
  final String name;
  final Suit suit;
  final Rank rank;
  final String imagePath;
  final String modelPath;
  final bool isModelLoaded;

  const Card({
    required this.id,
    required this.name,
    required this.suit,
    required this.rank,
    required this.imagePath,
    required this.modelPath,
    this.isModelLoaded = false,
  });

  String get displayName => '${rank.name} of ${suit.name}';
  
  String get shortName => '${rank.code}${suit.code}';

  Card copyWith({
    String? id,
    String? name,
    Suit? suit,
    Rank? rank,
    String? imagePath,
    String? modelPath,
    bool? isModelLoaded,
  }) {
    return Card(
      id: id ?? this.id,
      name: name ?? this.name,
      suit: suit ?? this.suit,
      rank: rank ?? this.rank,
      imagePath: imagePath ?? this.imagePath,
      modelPath: modelPath ?? this.modelPath,
      isModelLoaded: isModelLoaded ?? this.isModelLoaded,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Card &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Card(id: $id, name: $displayName)';
}
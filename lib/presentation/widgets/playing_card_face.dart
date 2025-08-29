import 'package:flutter/material.dart';
import '../../data/models/card.dart' as model;

class PlayingCardFace extends StatelessWidget {
  final model.Card card;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const PlayingCardFace({
    super.key,
    required this.card,
    this.width,
    this.height,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
    this.borderRadius = 12,
  });

  bool get _isRed => card.suit == model.Suit.hearts || card.suit == model.Suit.diamonds;

  @override
  Widget build(BuildContext context) {
    final double ratio = 1.4; // height = width * ratio when one is missing
    final double? w = width;
    final double? h = height ?? (w != null ? w * ratio : null);

    final Color symbolColor = _isRed ? Colors.red[700]! : Colors.black87;

    // Typography scales
    final double baseW = (w ?? 120).clamp(80, 220);
    final double rankSize = baseW * 0.45; // big rank
    final double suitSize = baseW * 0.38; // big suit symbol

    return Container(
      width: w,
      height: h,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.grey.shade300, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                card.rank.code,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: rankSize,
                  fontWeight: FontWeight.w800,
                  color: symbolColor,
                  height: 1.0,
                ),
              ),
              Text(
                card.suit.symbol,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: suitSize,
                  fontWeight: FontWeight.w700,
                  color: symbolColor,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

/// Singleton service to load and provide card display names from CSV.
///
/// CSV format:
///   card,name
///   da,エース刀
///   ...
/// - Duplicate card IDs: the last occurrence wins.
/// - Lines starting with '#' or blank lines are ignored.
class CardNameService {
  CardNameService._internal();
  static final CardNameService instance = CardNameService._internal();

  final Map<String, String> _names = <String, String>{};
  bool _loaded = false;
  Future<void>? _loading;

  /// Loads the CSV once. Safe to call multiple times.
  Future<void> load() async {
    if (_loaded) return;
    if (_loading != null) {
      await _loading;
      return;
    }
    _loading = _loadInternal();
    await _loading;
  }

  Future<void> _loadInternal() async {
    try {
      final csv = await rootBundle.loadString('assets/cards/names.csv');
      _parseCsv(csv);
      _loaded = true;
    } finally {
      _loading = null;
    }
  }

  void _parseCsv(String csv) {
    _names.clear();
    final lines = csv.split(RegExp(r'\r?\n'));
    if (lines.isEmpty) return;

    // Skip header if present (starts with 'card,name').
    int start = 0;
    if (lines.first.trim().toLowerCase().startsWith('card,')) {
      start = 1;
    }

    for (var i = start; i < lines.length; i++) {
      final raw = lines[i].trim();
      if (raw.isEmpty || raw.startsWith('#')) continue;
      final idx = raw.indexOf(',');
      if (idx <= 0) continue;
      final key = raw.substring(0, idx).trim().toLowerCase();
      final value = raw.substring(idx + 1).trim();
      if (key.isEmpty || value.isEmpty) continue;
      // Last occurrence wins
      _names[key] = value;
    }
  }

  /// Returns the localized/custom name for the given card id (e.g., 'da'),
  /// or null if not found or names not loaded yet.
  String? tryGet(String cardId) {
    if (cardId.isEmpty) return null;
    return _names[cardId.toLowerCase()];
  }
}

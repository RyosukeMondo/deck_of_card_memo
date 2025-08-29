import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/services/card_name_service.dart';
import 'data/services/card_data_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load CSV names once at startup so they are available app-wide.
  await CardNameService.instance.load();
  // Rebuild cards from loaded names (handles hot restart or updated CSV during dev).
  CardDataService.refreshFromNames();
  runApp(
    const ProviderScope(
      child: CardMemoApp(),
    ),
  );
}

# Component Specifications - Flutter Card Memorization App

## 3D Rendering Component Specification

### Flutter3DController Integration

#### Core 3D Viewer Component
```dart
// lib/widgets/card_3d_viewer.dart
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

class Card3DViewer extends ConsumerStatefulWidget {
  final String cardId;
  final bool enableInteraction;
  final VoidCallback? onModelLoaded;
  final VoidCallback? onLoadError;
  
  const Card3DViewer({
    Key? key,
    required this.cardId,
    this.enableInteraction = true,
    this.onModelLoaded,
    this.onLoadError,
  }) : super(key: key);

  @override
  ConsumerState<Card3DViewer> createState() => _Card3DViewerState();
}

class _Card3DViewerState extends ConsumerState<Card3DViewer> {
  Flutter3DController controller = Flutter3DController();
  bool isModelLoaded = false;
  String? currentModelPath;

  @override
  Widget build(BuildContext context) {
    final card = ref.watch(currentCardProvider);
    
    return FutureBuilder<bool>(
      future: DeferredAssetLoader.ensureModelLoaded(widget.cardId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }
        
        if (snapshot.hasError || !snapshot.data!) {
          return _buildErrorState();
        }
        
        return _build3DViewer(card.modelPath);
      },
    );
  }

  Widget _build3DViewer(String modelPath) {
    return Flutter3DViewer(
      controller: controller,
      src: modelPath,
      // Interactive controls
      autoRotate: false,
      cameraControls: widget.enableInteraction,
      // Camera settings
      cameraOrbit: const CameraOrbit(0, 75, 105),
      cameraTarget: const CameraTarget(0, 0, 0),
      // Environment
      environmentImage: null,
      backgroundColor: const Color(0xFF2E7D32),
      // Loading callbacks
      onLoad: () {
        setState(() => isModelLoaded = true);
        widget.onModelLoaded?.call();
      },
      onError: (error) {
        widget.onLoadError?.call();
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading 3D Model...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48),
          Text('Failed to load 3D model'),
          TextButton(
            onPressed: () => setState(() {}), // Retry
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Programmatic controls
  void resetCamera() {
    controller.setCameraOrbit(0, 75, 105);
    controller.setCameraTarget(0, 0, 0);
  }

  void focusOnCard() {
    controller.setCameraOrbit(0, 90, 80);
    controller.setCameraTarget(0, 0, 0);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

#### 3D Controller Service
```dart
// lib/services/model_3d_controller.dart
class Model3DControllerService {
  static const Map<String, CameraPosition> _presetPositions = {
    'default': CameraPosition(orbit: CameraOrbit(0, 75, 105)),
    'front': CameraPosition(orbit: CameraOrbit(0, 90, 80)),
    'back': CameraPosition(orbit: CameraOrbit(180, 90, 80)),
    'top': CameraPosition(orbit: CameraOrbit(0, 0, 100)),
    'closeup': CameraPosition(orbit: CameraOrbit(0, 75, 60)),
  };

  static Future<void> animateToPosition(
    Flutter3DController controller,
    String positionName, {
    Duration duration = const Duration(milliseconds: 800),
  }) async {
    final position = _presetPositions[positionName];
    if (position == null) return;

    await controller.setCameraOrbit(
      position.orbit.theta,
      position.orbit.phi, 
      position.orbit.radius,
    );
  }

  static void enableAutoRotation(Flutter3DController controller) {
    // Note: flutter_3d_controller auto-rotate via web component
    controller.htmlElement?.setAttribute('auto-rotate', '');
  }

  static void disableAutoRotation(Flutter3DController controller) {
    controller.htmlElement?.removeAttribute('auto-rotate');
  }
}

class CameraPosition {
  final CameraOrbit orbit;
  final CameraTarget? target;
  
  const CameraPosition({required this.orbit, this.target});
}
```

## State Management Component Specification

### Riverpod Provider Architecture

#### Card State Management
```dart
// lib/providers/card_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    // This would need to work with a shuffled card list
    // Implementation depends on shuffle strategy
    state = 0; // Reset to first of shuffled deck
  }
}

enum ViewMode { image, model3d }

class ViewModeNotifier extends StateNotifier<ViewMode> {
  ViewModeNotifier() : super(ViewMode.image);

  void toggleMode() {
    state = state == ViewMode.image ? ViewMode.model3d : ViewMode.image;
  }

  void setMode(ViewMode mode) {
    state = mode;
  }
}
```

#### Quiz State Management
```dart
// lib/providers/quiz_providers.dart
final quizStateProvider = StateNotifierProvider<QuizNotifier, QuizState>(
  (ref) => QuizNotifier(),
);

final quizControllerProvider = Provider<QuizController>((ref) {
  return QuizController(ref);
});

class QuizState {
  final List<QuizQuestion> questions;
  final int currentQuestionIndex;
  final Map<int, QuizAnswer> answers;
  final QuizMode mode;
  final QuizStatus status;
  final DateTime? startTime;
  final DateTime? endTime;

  const QuizState({
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.answers = const {},
    this.mode = QuizMode.identification,
    this.status = QuizStatus.notStarted,
    this.startTime,
    this.endTime,
  });

  // Computed properties
  int get correctAnswers => answers.values.where((a) => a.isCorrect).length;
  int get incorrectAnswers => answers.values.where((a) => !a.isCorrect).length;
  double get accuracy => answers.isEmpty ? 0.0 : correctAnswers / answers.length;
  Duration? get elapsedTime => startTime != null && endTime != null 
    ? endTime!.difference(startTime!) : null;

  QuizState copyWith({
    List<QuizQuestion>? questions,
    int? currentQuestionIndex,
    Map<int, QuizAnswer>? answers,
    QuizMode? mode,
    QuizStatus? status,
    DateTime? startTime,
    DateTime? endTime,
  }) => QuizState(
    questions: questions ?? this.questions,
    currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
    answers: answers ?? this.answers,
    mode: mode ?? this.mode,
    status: status ?? this.status,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
  );
}

class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier() : super(const QuizState());

  void startQuiz(QuizMode mode, {int questionCount = 10}) {
    final questions = _generateQuestions(mode, questionCount);
    state = state.copyWith(
      questions: questions,
      currentQuestionIndex: 0,
      answers: {},
      mode: mode,
      status: QuizStatus.inProgress,
      startTime: DateTime.now(),
    );
  }

  void answerQuestion(String answer) {
    final currentQuestion = state.questions[state.currentQuestionIndex];
    final isCorrect = _validateAnswer(currentQuestion, answer);
    
    final newAnswers = Map<int, QuizAnswer>.from(state.answers);
    newAnswers[state.currentQuestionIndex] = QuizAnswer(
      questionIndex: state.currentQuestionIndex,
      userAnswer: answer,
      correctAnswer: currentQuestion.correctAnswer,
      isCorrect: isCorrect,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(answers: newAnswers);

    // Auto-advance to next question
    if (state.currentQuestionIndex < state.questions.length - 1) {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1);
    } else {
      _completeQuiz();
    }
  }

  void _completeQuiz() {
    state = state.copyWith(
      status: QuizStatus.completed,
      endTime: DateTime.now(),
    );
  }

  List<QuizQuestion> _generateQuestions(QuizMode mode, int count) {
    // Implementation for generating quiz questions based on mode
    // This would use the card data to create appropriate questions
    return [];
  }

  bool _validateAnswer(QuizQuestion question, String answer) {
    return question.correctAnswer.toLowerCase() == answer.toLowerCase();
  }
}

enum QuizMode { identification, memory, sequence, matching }
enum QuizStatus { notStarted, inProgress, paused, completed }

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final Card? relatedCard;
  final QuizQuestionType type;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.relatedCard,
    required this.type,
  });
}

enum QuizQuestionType { multipleChoice, trueFalse, textInput, cardSelection }

class QuizAnswer {
  final int questionIndex;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final DateTime timestamp;

  const QuizAnswer({
    required this.questionIndex,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.timestamp,
  });
}
```

#### Application State Provider
```dart
// lib/providers/app_providers.dart
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>(
  (ref) => AppStateNotifier(),
);

class AppState {
  final bool isLoading;
  final String? error;
  final AppMode mode;
  final UserPreferences preferences;
  final Map<String, bool> deferredAssetsLoaded;

  const AppState({
    this.isLoading = false,
    this.error,
    this.mode = AppMode.cardViewer,
    required this.preferences,
    this.deferredAssetsLoaded = const {},
  });

  AppState copyWith({
    bool? isLoading,
    String? error,
    AppMode? mode,
    UserPreferences? preferences,
    Map<String, bool>? deferredAssetsLoaded,
  }) => AppState(
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    mode: mode ?? this.mode,
    preferences: preferences ?? this.preferences,
    deferredAssetsLoaded: deferredAssetsLoaded ?? this.deferredAssetsLoaded,
  );
}

enum AppMode { cardViewer, quiz, settings, statistics }

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState(preferences: UserPreferences.defaults()));

  void setMode(AppMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void markAssetLoaded(String assetId) {
    final newMap = Map<String, bool>.from(state.deferredAssetsLoaded);
    newMap[assetId] = true;
    state = state.copyWith(deferredAssetsLoaded: newMap);
  }
}
```

## UI Component Specifications

### Main Card Display Widget
```dart
// lib/widgets/card_display_widget.dart
class CardDisplayWidget extends ConsumerWidget {
  const CardDisplayWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(viewModeProvider);
    final currentCard = ref.watch(currentCardProvider);
    final isLoading = ref.watch(appStateProvider.select((state) => state.isLoading));

    return GestureDetector(
      onTap: () => ref.read(viewModeProvider.notifier).toggleMode(),
      child: Container(
        height: 400,
        width: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Main content
              AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: viewMode == ViewMode.image
                    ? CardImageViewer(card: currentCard)
                    : Card3DViewer(cardId: currentCard.id),
              ),
              
              // Loading overlay
              if (isLoading)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),

              // View mode indicator
              Positioned(
                top: 8,
                right: 8,
                child: ViewModeIndicator(mode: viewMode),
              ),

              // Tap hint
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Tap to switch view',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Navigation Controls Component
```dart
// lib/widgets/navigation_controls.dart
class NavigationControls extends ConsumerWidget {
  const NavigationControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentCardIndexProvider);
    final cardNotifier = ref.read(currentCardIndexProvider.notifier);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous button
          IconButton(
            onPressed: cardNotifier.previousCard,
            icon: Icon(Icons.chevron_left, size: 32),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),

          // Card counter
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).primaryColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${currentIndex + 1}/52',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Shuffle button
          IconButton(
            onPressed: () {
              // Show confirmation dialog
              _showShuffleDialog(context, ref);
            },
            icon: Icon(Icons.shuffle),
            style: IconButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),

          // Quiz mode button
          FilledButton.icon(
            onPressed: () => _startQuizMode(context, ref),
            icon: Icon(Icons.quiz),
            label: Text('Quiz'),
          ),

          // Next button
          IconButton(
            onPressed: cardNotifier.nextCard,
            icon: Icon(Icons.chevron_right, size: 32),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showShuffleDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Shuffle Cards'),
        content: Text('Randomize the order of all cards?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(currentCardIndexProvider.notifier).shuffle();
              Navigator.pop(context);
            },
            child: Text('Shuffle'),
          ),
        ],
      ),
    );
  }

  void _startQuizMode(BuildContext context, WidgetRef ref) {
    ref.read(appStateProvider.notifier).setMode(AppMode.quiz);
    // Navigate to quiz screen or show quiz modal
  }
}
```

### Performance Monitoring Component
```dart
// lib/widgets/performance_monitor.dart
class PerformanceMonitor extends ConsumerStatefulWidget {
  final Widget child;
  
  const PerformanceMonitor({Key? key, required this.child}) : super(key: key);

  @override
  ConsumerState<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends ConsumerState<PerformanceMonitor> {
  late Timer _performanceTimer;
  double _currentFPS = 0.0;
  int _frameCount = 0;
  DateTime _lastFrameTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startPerformanceMonitoring();
  }

  void _startPerformanceMonitoring() {
    _performanceTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _calculateFPS();
    });

    WidgetsBinding.instance.addPersistentFrameCallback(_onFrame);
  }

  void _onFrame(Duration timestamp) {
    _frameCount++;
    WidgetsBinding.instance.addPersistentFrameCallback(_onFrame);
  }

  void _calculateFPS() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastFrameTime).inMilliseconds;
    
    if (elapsed > 0) {
      setState(() {
        _currentFPS = (_frameCount * 1000) / elapsed;
        _frameCount = 0;
        _lastFrameTime = now;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // Performance overlay (debug mode only)
        if (kDebugMode)
          Positioned(
            top: 40,
            left: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'FPS: ${_currentFPS.toStringAsFixed(1)}',
                style: TextStyle(
                  color: _currentFPS >= 55 ? Colors.green : 
                         _currentFPS >= 30 ? Colors.yellow : Colors.red,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _performanceTimer.cancel();
    super.dispose();
  }
}
```

These component specifications provide detailed implementation guidance for the core 3D rendering system using flutter_3d_controller and comprehensive state management using Riverpod, addressing all the technical requirements from the Japanese technical report.
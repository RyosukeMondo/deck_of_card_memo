import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/quiz.dart';
import '../../data/models/card.dart';
import '../../data/services/card_data_service.dart';
import 'dart:math';

// Quiz state provider
final quizStateProvider = StateNotifierProvider<QuizNotifier, QuizState>(
  (ref) => QuizNotifier(),
);

// Quiz controller provider
final quizControllerProvider = Provider<QuizController>((ref) {
  return QuizController(ref);
});

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
      questionStartTime: DateTime.now(),
      endTime: null,
    );
  }

  void answerQuestion(String answer) {
    if (state.currentQuestion == null) return;

    final currentQuestion = state.currentQuestion!;
    final isCorrect = _validateAnswer(currentQuestion, answer);
    final responseTime = state.questionStartTime != null 
        ? DateTime.now().difference(state.questionStartTime!)
        : Duration.zero;
    
    final newAnswers = Map<int, QuizAnswer>.from(state.answers);
    newAnswers[state.currentQuestionIndex] = QuizAnswer(
      questionIndex: state.currentQuestionIndex,
      userAnswer: answer,
      correctAnswer: currentQuestion.correctAnswer,
      isCorrect: isCorrect,
      timestamp: DateTime.now(),
      responseTime: responseTime,
    );

    state = state.copyWith(answers: newAnswers);

    // Auto-advance to next question
    if (state.currentQuestionIndex < state.questions.length - 1) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
        questionStartTime: DateTime.now(),
      );
    } else {
      _completeQuiz();
    }
  }

  void pauseQuiz() {
    if (state.status == QuizStatus.inProgress) {
      state = state.copyWith(status: QuizStatus.paused);
    }
  }

  void resumeQuiz() {
    if (state.status == QuizStatus.paused) {
      state = state.copyWith(
        status: QuizStatus.inProgress,
        questionStartTime: DateTime.now(),
      );
    }
  }

  void resetQuiz() {
    state = const QuizState();
  }

  void _completeQuiz() {
    state = state.copyWith(
      status: QuizStatus.completed,
      endTime: DateTime.now(),
    );
  }

  List<QuizQuestion> _generateQuestions(QuizMode mode, int count) {
    final allCards = CardDataService.getAllCards();
    final random = Random();
    final questions = <QuizQuestion>[];

    switch (mode) {
      case QuizMode.identification:
        // Generate identification questions
        for (int i = 0; i < count; i++) {
          final correctCard = allCards[random.nextInt(allCards.length)];
          final wrongOptions = _getRandomCards(allCards, correctCard, 3);
          final allOptions = [correctCard.displayName, ...wrongOptions.map((c) => c.displayName)]
              ..shuffle();

          questions.add(QuizQuestion(
            id: 'id_${i}_${correctCard.id}',
            question: 'What card is this?',
            options: allOptions,
            correctAnswer: correctCard.displayName,
            relatedCard: correctCard,
            type: QuizQuestionType.multipleChoice,
          ));
        }
        break;

      case QuizMode.memory:
        // Generate memory-based questions
        for (int i = 0; i < count; i++) {
          final correctCard = allCards[random.nextInt(allCards.length)];
          questions.add(QuizQuestion(
            id: 'mem_${i}_${correctCard.id}',
            question: 'Which suit does the ${correctCard.rank.name} belong to?',
            options: Suit.values.map((s) => s.name).toList()..shuffle(),
            correctAnswer: correctCard.suit.name,
            relatedCard: correctCard,
            type: QuizQuestionType.multipleChoice,
          ));
        }
        break;

      case QuizMode.sequence:
        // Generate sequence questions
        for (int i = 0; i < count; i++) {
          final suit = Suit.values[random.nextInt(Suit.values.length)];
          final startRank = Rank.values[random.nextInt(Rank.values.length - 2)];
          final nextRank = Rank.values[startRank.value];
          
          questions.add(QuizQuestion(
            id: 'seq_${i}_${suit.code}${startRank.code}',
            question: 'What comes after ${startRank.name} of ${suit.name}?',
            options: Rank.values.map((r) => r.name).toList()..shuffle(),
            correctAnswer: nextRank.name,
            relatedCard: CardDataService.getCardsBySuit(suit)
                .firstWhere((c) => c.rank == startRank),
            type: QuizQuestionType.multipleChoice,
          ));
        }
        break;

      case QuizMode.matching:
        // Generate matching questions
        for (int i = 0; i < count; i++) {
          final correctCard = allCards[random.nextInt(allCards.length)];
          final isRankQuestion = random.nextBool();
          
          if (isRankQuestion) {
            final matchingCards = CardDataService.getCardsByRank(correctCard.rank);
            final wrongOptions = _getRandomCards(allCards, correctCard, 3);
            
            questions.add(QuizQuestion(
              id: 'match_rank_${i}_${correctCard.id}',
              question: 'Which card has the same rank as ${correctCard.displayName}?',
              options: [
                matchingCards[1].displayName, // Another card with same rank
                ...wrongOptions.map((c) => c.displayName)
              ]..shuffle(),
              correctAnswer: matchingCards[1].displayName,
              relatedCard: correctCard,
              type: QuizQuestionType.multipleChoice,
            ));
          } else {
            final matchingCards = CardDataService.getCardsBySuit(correctCard.suit);
            final wrongOptions = _getRandomCards(allCards, correctCard, 3);
            
            questions.add(QuizQuestion(
              id: 'match_suit_${i}_${correctCard.id}',
              question: 'Which card has the same suit as ${correctCard.displayName}?',
              options: [
                matchingCards[random.nextInt(matchingCards.length)].displayName,
                ...wrongOptions.map((c) => c.displayName)
              ]..shuffle(),
              correctAnswer: matchingCards[random.nextInt(matchingCards.length)].displayName,
              relatedCard: correctCard,
              type: QuizQuestionType.multipleChoice,
            ));
          }
        }
        break;
    }

    return questions;
  }

  List<Card> _getRandomCards(List<Card> allCards, Card excludeCard, int count) {
    final availableCards = allCards.where((c) => c != excludeCard).toList();
    final random = Random();
    final result = <Card>[];
    
    while (result.length < count && result.length < availableCards.length) {
      final randomCard = availableCards[random.nextInt(availableCards.length)];
      if (!result.contains(randomCard)) {
        result.add(randomCard);
      }
    }
    
    return result;
  }

  bool _validateAnswer(QuizQuestion question, String answer) {
    return question.correctAnswer.toLowerCase().trim() == answer.toLowerCase().trim();
  }
}

class QuizController {
  final Ref ref;

  QuizController(this.ref);

  void startQuiz(QuizMode mode, {int questionCount = 10}) {
    ref.read(quizStateProvider.notifier).startQuiz(mode, questionCount: questionCount);
  }

  void answerQuestion(String answer) {
    ref.read(quizStateProvider.notifier).answerQuestion(answer);
  }

  void pauseQuiz() {
    ref.read(quizStateProvider.notifier).pauseQuiz();
  }

  void resumeQuiz() {
    ref.read(quizStateProvider.notifier).resumeQuiz();
  }

  void resetQuiz() {
    ref.read(quizStateProvider.notifier).resetQuiz();
  }

  QuizState getQuizState() {
    return ref.read(quizStateProvider);
  }

  bool isQuizInProgress() {
    final state = ref.read(quizStateProvider);
    return state.status == QuizStatus.inProgress;
  }

  bool isQuizCompleted() {
    final state = ref.read(quizStateProvider);
    return state.status == QuizStatus.completed;
  }

  double getAccuracy() {
    final state = ref.read(quizStateProvider);
    return state.accuracy;
  }

  Duration? getElapsedTime() {
    final state = ref.read(quizStateProvider);
    return state.totalTime;
  }
}
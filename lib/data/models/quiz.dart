import 'card.dart';

enum QuizMode { 
  identification('Identification', 'Identify the card shown'),
  memory('Memory', 'Remember the sequence of cards'),
  sequence('Sequence', 'Arrange cards in correct order'),
  matching('Matching', 'Match pairs of cards');

  const QuizMode(this.displayName, this.description);
  
  final String displayName;
  final String description;
}

enum QuizStatus { 
  notStarted('Not Started'),
  inProgress('In Progress'),
  paused('Paused'),
  completed('Completed');

  const QuizStatus(this.displayName);
  
  final String displayName;
}

enum QuizQuestionType { 
  multipleChoice('Multiple Choice'),
  trueFalse('True/False'),
  textInput('Text Input'),
  cardSelection('Card Selection');

  const QuizQuestionType(this.displayName);
  
  final String displayName;
}

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizQuestion &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class QuizAnswer {
  final int questionIndex;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final DateTime timestamp;
  final Duration responseTime;

  const QuizAnswer({
    required this.questionIndex,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.timestamp,
    required this.responseTime,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizAnswer &&
          runtimeType == other.runtimeType &&
          questionIndex == other.questionIndex &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(questionIndex, timestamp);
}

class QuizState {
  final List<QuizQuestion> questions;
  final int currentQuestionIndex;
  final Map<int, QuizAnswer> answers;
  final QuizMode mode;
  final QuizStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? questionStartTime;

  const QuizState({
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.answers = const {},
    this.mode = QuizMode.identification,
    this.status = QuizStatus.notStarted,
    this.startTime,
    this.endTime,
    this.questionStartTime,
  });

  // Computed properties
  int get correctAnswers => answers.values.where((a) => a.isCorrect).length;
  
  int get incorrectAnswers => answers.values.where((a) => !a.isCorrect).length;
  
  double get accuracy => answers.isEmpty ? 0.0 : correctAnswers / answers.length;
  
  Duration? get elapsedTime => startTime != null && endTime != null 
      ? endTime!.difference(startTime!) : null;
  
  Duration? get totalTime => startTime != null
      ? (endTime ?? DateTime.now()).difference(startTime!)
      : null;
  
  bool get isCompleted => currentQuestionIndex >= questions.length;
  
  QuizQuestion? get currentQuestion => 
      currentQuestionIndex < questions.length 
          ? questions[currentQuestionIndex] 
          : null;

  QuizState copyWith({
    List<QuizQuestion>? questions,
    int? currentQuestionIndex,
    Map<int, QuizAnswer>? answers,
    QuizMode? mode,
    QuizStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? questionStartTime,
  }) => QuizState(
    questions: questions ?? this.questions,
    currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
    answers: answers ?? this.answers,
    mode: mode ?? this.mode,
    status: status ?? this.status,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    questionStartTime: questionStartTime ?? this.questionStartTime,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizState &&
          runtimeType == other.runtimeType &&
          questions == other.questions &&
          currentQuestionIndex == other.currentQuestionIndex &&
          answers == other.answers &&
          mode == other.mode &&
          status == other.status;

  @override
  int get hashCode => Object.hash(
    questions, 
    currentQuestionIndex, 
    answers, 
    mode, 
    status
  );
}
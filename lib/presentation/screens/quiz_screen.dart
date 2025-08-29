import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quiz_providers.dart';
import '../../data/models/quiz.dart';
import '../../core/themes/app_theme.dart';

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(quizStateProvider);
    final quizController = ref.watch(quizControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Mode'),
        leading: IconButton(
          onPressed: () {
            if (quizState.status == QuizStatus.inProgress) {
              _showExitConfirmation(context, ref);
            } else {
              Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          if (quizState.status == QuizStatus.inProgress)
            IconButton(
              onPressed: () => quizController.pauseQuiz(),
              icon: const Icon(Icons.pause),
              tooltip: 'Pause Quiz',
            ),
        ],
      ),
      body: _buildBody(context, quizState, quizController),
    );
  }

  Widget _buildBody(BuildContext context, QuizState quizState,
      QuizController quizController) {
    switch (quizState.status) {
      case QuizStatus.notStarted:
        return _buildQuizSelection(context, quizController);
      case QuizStatus.inProgress:
        return _buildActiveQuiz(context, quizState, quizController);
      case QuizStatus.paused:
        return _buildPausedQuiz(context, quizState, quizController);
      case QuizStatus.completed:
        return _buildQuizResults(context, quizState, quizController);
    }
  }

  Widget _buildQuizSelection(
      BuildContext context, QuizController quizController) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.quiz,
            size: 80,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Choose Quiz Mode',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
          ),
          const SizedBox(height: 32),
          ...QuizMode.values.map((mode) => _buildQuizModeCard(
                context,
                mode,
                () => quizController.startQuiz(mode, questionCount: 10),
              )),
        ],
      ),
    );
  }

  Widget _buildQuizModeCard(
      BuildContext context, QuizMode mode, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTheme.cardRadius,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getQuizModeIcon(mode),
                      color: AppTheme.primaryColor,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mode.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mode.description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveQuiz(BuildContext context, QuizState quizState,
      QuizController quizController) {
    final currentQuestion = quizState.currentQuestion;
    if (currentQuestion == null) {
      return const Center(child: Text('No questions available'));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (quizState.currentQuestionIndex + 1) /
                quizState.questions.length,
            backgroundColor: Colors.grey[300],
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),

          // Question counter
          Text(
            'Question ${quizState.currentQuestionIndex + 1} of ${quizState.questions.length}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),

          // Question
          Text(
            currentQuestion.question,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 32),

          // Answer options
          ...currentQuestion.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton(
                onPressed: () => quizController.answerQuestion(option),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.centerLeft,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + index), // A, B, C, D
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        option,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const Spacer(),

          // Quiz stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: AppTheme.cardRadius,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Correct', quizState.correctAnswers.toString()),
                _buildStatItem(
                    'Incorrect', quizState.incorrectAnswers.toString()),
                _buildStatItem('Accuracy',
                    '${(quizState.accuracy * 100).toStringAsFixed(1)}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPausedQuiz(BuildContext context, QuizState quizState,
      QuizController quizController) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pause_circle,
              size: 80,
              color: AppTheme.warningColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Quiz Paused',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Question ${quizState.currentQuestionIndex + 1} of ${quizState.questions.length}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => quizController.resumeQuiz(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resume Quiz'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizResults(BuildContext context, QuizState quizState,
      QuizController quizController) {
    final accuracy = quizState.accuracy * 100;
    final elapsedTime = quizState.elapsedTime;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            accuracy >= 80
                ? Icons.emoji_events
                : accuracy >= 60
                    ? Icons.thumb_up
                    : Icons.refresh,
            size: 80,
            color: accuracy >= 80
                ? const Color(0xFFFFD700) // Gold color
                : accuracy >= 60
                    ? AppTheme.successColor
                    : AppTheme.warningColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Quiz Completed!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 32),

          // Results summary
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: AppTheme.cardRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildResultRow(
                    'Questions', quizState.questions.length.toString()),
                _buildResultRow('Correct', quizState.correctAnswers.toString()),
                _buildResultRow(
                    'Incorrect', quizState.incorrectAnswers.toString()),
                _buildResultRow('Accuracy', '${accuracy.toStringAsFixed(1)}%'),
                if (elapsedTime != null)
                  _buildResultRow('Time',
                      '${elapsedTime.inMinutes}:${(elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}'),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => quizController.resetQuiz(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home),
                label: const Text('Back to Cards'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getQuizModeIcon(QuizMode mode) {
    switch (mode) {
      case QuizMode.identification:
        return Icons.visibility;
      case QuizMode.memory:
        return Icons.psychology;
      case QuizMode.sequence:
        return Icons.sort;
      case QuizMode.matching:
        return Icons.compare_arrows;
    }
  }

  void _showExitConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text('Your progress will be lost if you exit now.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Quiz'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(quizStateProvider.notifier).resetQuiz();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to main screen
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

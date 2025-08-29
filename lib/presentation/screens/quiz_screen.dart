import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quiz_providers.dart';
import '../../data/models/quiz.dart';
import '../../data/models/card.dart' as model;
import '../../data/services/card_data_service.dart';
import '../../core/themes/app_theme.dart';
import '../widgets/playing_card_face.dart';

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
          const Icon(Icons.quiz, size: 80, color: AppTheme.primaryColor),
          const SizedBox(height: 24),
          Text(
            'Choose Memorization Mode',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
          ),
          const SizedBox(height: 32),
          _buildQuizModeCard(
            context,
            QuizMode.identification,
            () => quizController.startQuiz(QuizMode.identification, questionCount: 10),
            titleOverride: 'Card → Image',
            descOverride: 'See card text, pick matching image',
          ),
          _buildQuizModeCard(
            context,
            QuizMode.memory,
            () => quizController.startQuiz(QuizMode.memory, questionCount: 10),
            titleOverride: 'Image → Card',
            descOverride: 'See image, pick matching card',
          ),
        ],
      ),
    );
  }

  Widget _buildQuizModeCard(
      BuildContext context, QuizMode mode, VoidCallback onTap, {String? titleOverride, String? descOverride}) {
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
                            titleOverride ?? mode.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            descOverride ?? mode.description,
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
    final current = quizState.currentQuestion;
    if (current == null) return const Center(child: Text('No questions available'));

    // Key by question id to ensure state resets (e.g., selected option) per question.
    return _ActiveMemorizationView(key: ValueKey(current.id), state: quizState);
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

// ===================== Active Memorization View (SRP) =====================
class _ActiveMemorizationView extends ConsumerStatefulWidget {
  final QuizState state;
  const _ActiveMemorizationView({Key? key, required this.state}) : super(key: key);

  @override
  ConsumerState<_ActiveMemorizationView> createState() => _ActiveMemorizationViewState();
}

class _ActiveMemorizationViewState extends ConsumerState<_ActiveMemorizationView> {
  int? _selectedIndex;
  bool _answered = false;
  String? _selectedAnswerValue;
  List<_OptionItem>? _options; // cache options per question

  @override
  void initState() {
    super.initState();
    _selectedIndex = null;
    _answered = false;
    _selectedAnswerValue = null;
    _options = _buildOptions(widget.state.currentQuestion!, widget.state.mode);
  }

  @override
  void didUpdateWidget(covariant _ActiveMemorizationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.state.currentQuestion?.id;
    final newId = widget.state.currentQuestion?.id;
    if (oldId != newId) {
      debugPrint('[Quiz] Question changed: $oldId -> $newId. Resetting selection.');
      setState(() {
        _selectedIndex = null;
        _answered = false;
        _selectedAnswerValue = null;
        _options = _buildOptions(widget.state.currentQuestion!, widget.state.mode);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizState = widget.state;
    final question = quizState.currentQuestion!;
    final options = _options ?? _buildOptions(question, quizState.mode);
    debugPrint('[Quiz] Showing question ${quizState.currentQuestionIndex + 1}/${quizState.questions.length} id=${question.id}');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: (quizState.currentQuestionIndex + 1) / quizState.questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text('Question ${quizState.currentQuestionIndex + 1} of ${quizState.questions.length}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.primaryColor)),
          const SizedBox(height: 16),
          if (quizState.mode == QuizMode.identification)
            _PromptCardText(card: question.relatedCard)
          else
            _PromptCardImage(card: question.relatedCard),
          const SizedBox(height: 12),
          _OptionsGrid(
            options: options,
            selectedIndex: _selectedIndex,
            answered: _answered,
            onTap: (index, option) {
              if (_answered) return; // prevent changes after answering
              debugPrint('[Quiz] Selected option index=$index label=${option.label} correct=${option.isCorrect}');
              setState(() {
                _selectedIndex = index;
                _answered = true;
                _selectedAnswerValue = option.answerValue;
              });
            },
          ),
          const SizedBox(height: 12),
          _StatsBar(state: quizState),
          const SizedBox(height: 12),
          if (_answered) _AnswerFooter(
            isCorrect: options[_selectedIndex!].isCorrect,
            correctLabel: options.firstWhere((o) => o.isCorrect).label,
            onContinue: () {
              if (_selectedAnswerValue == null) return;
              debugPrint('[Quiz] Submitting answer value=${_selectedAnswerValue}');
              ref.read(quizControllerProvider).answerQuestion(_selectedAnswerValue!);
            },
            isLast: quizState.currentQuestionIndex + 1 >= quizState.questions.length,
          ),
        ],
      ),
    );
  }

  List<_OptionItem> _buildOptions(QuizQuestion q, QuizMode mode) {
    final List<model.Card> all = CardDataService.getAllCards();
    final model.Card? correct = q.relatedCard;
    if (correct == null) return const [];

    final others = all.where((c) => c.id != correct.id).toList()..shuffle();
    final picks = others.take(3).toList()..add(correct);
    picks.shuffle(); // shuffle once; result cached per question

    final isImageChoice = mode == QuizMode.identification; // Card→Image => show images
    return picks
        .map((c) => _OptionItem(
              label: _shortLabel(c),
              imagePath: c.imagePath,
              isImage: isImageChoice,
              isCorrect: c.id == correct.id,
              answerValue: c.displayName,
              card: c,
            ))
        .toList();
  }

  String _shortLabel(model.Card c) => '${c.rank.code} ${c.suit.symbol}';
}

// ============================== Shared Widgets =============================
class _PromptCardText extends StatelessWidget {
  final model.Card? card;
  const _PromptCardText({required this.card});
  @override
  Widget build(BuildContext context) {
    if (card == null) return const SizedBox.shrink();
    return Center(
      child: PlayingCardFace(card: card!, width: 96),
    );
  }
}

class _PromptCardImage extends StatelessWidget {
  final model.Card? card;
  const _PromptCardImage({required this.card});
  @override
  Widget build(BuildContext context) {
    if (card == null) return const SizedBox.shrink();
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: AppTheme.cardRadius,
        child: _FallbackAssetImage(
          path: card!.imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      ),
    );
  }
}

class _OptionsGrid extends StatelessWidget {
  final List<_OptionItem> options;
  final int? selectedIndex;
  final bool answered;
  final void Function(int, _OptionItem) onTap;
  const _OptionsGrid({required this.options, required this.selectedIndex, required this.answered, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool images = options.isNotEmpty && options.first.isImage;
    if (images) {
      // Card → Image: 2x2 grid of images
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.2,
        ),
        itemCount: options.length,
        itemBuilder: (context, i) {
          final opt = options[i];
          final isSelected = i == selectedIndex;
          Color borderColor;
          if (answered) {
            if (opt.isCorrect) {
              borderColor = AppTheme.successColor;
            } else if (isSelected && !opt.isCorrect) {
              borderColor = AppTheme.warningColor;
            } else {
              borderColor = Colors.transparent;
            }
          } else {
            borderColor = isSelected ? AppTheme.primaryColor : Colors.transparent;
          }

          return InkWell(
            onTap: () => onTap(i, opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                borderRadius: AppTheme.cardRadius,
                border: Border.all(color: borderColor, width: 2),
                color: Theme.of(context).cardColor,
              ),
              padding: const EdgeInsets.all(6),
              child: ClipRRect(
                borderRadius: AppTheme.cardRadius,
                child: _FallbackAssetImage(
                  path: opt.imagePath!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          );
        },
      );
    } else {
      // Image → Card: single row of 4 card faces
      return SizedBox(
        height: 84,
        child: Row(
          children: List.generate(options.length, (i) {
            final opt = options[i];
            final isSelected = i == selectedIndex;
            Color borderColor;
            if (answered) {
              if (opt.isCorrect) {
                borderColor = AppTheme.successColor;
              } else if (isSelected && !opt.isCorrect) {
                borderColor = AppTheme.warningColor;
              } else {
                borderColor = Colors.transparent;
              }
            } else {
              borderColor = isSelected ? AppTheme.primaryColor : Colors.transparent;
            }

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: InkWell(
                  onTap: () => onTap(i, opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      borderRadius: AppTheme.cardRadius,
                      border: Border.all(color: borderColor, width: 2),
                      color: Theme.of(context).cardColor,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Center(
                      child: PlayingCardFace(card: opt.card!, width: 56),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    }
  }
}

class _StatsBar extends StatelessWidget {
  final QuizState state;
  const _StatsBar({required this.state});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: AppTheme.cardRadius,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Stat(label: 'Correct', value: state.correctAnswers.toString()),
          _Stat(label: 'Incorrect', value: state.incorrectAnswers.toString()),
          _Stat(label: 'Accuracy', value: '${(state.accuracy * 100).toStringAsFixed(1)}%'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _AnswerFooter extends StatelessWidget {
  final bool isCorrect;
  final String correctLabel;
  final VoidCallback onContinue;
  final bool isLast;

  const _AnswerFooter({
    required this.isCorrect,
    required this.correctLabel,
    required this.onContinue,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final Color bannerColor = isCorrect ? AppTheme.successColor.withOpacity(0.12) : AppTheme.warningColor.withOpacity(0.12);
    final Color textColor = isCorrect ? AppTheme.successColor : AppTheme.warningColor;
    final String message = isCorrect ? 'Correct!' : 'Incorrect. Correct: $correctLabel';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: AppTheme.cardRadius,
      ),
      child: Row(
        children: [
          Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: textColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
            ),
          ),
          FilledButton(
            onPressed: onContinue,
            child: Text(isLast ? 'Finish' : 'Continue'),
          ),
        ],
      ),
    );
  }
}

class _OptionItem {
  final String label;
  final String? imagePath;
  final bool isImage;
  final bool isCorrect;
  final String answerValue;
  final model.Card? card;
  const _OptionItem({required this.label, required this.imagePath, required this.isImage, required this.isCorrect, required this.answerValue, this.card});
}

// ============================== Utilities ==============================
class _FallbackAssetImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const _FallbackAssetImage({
    required this.path,
    this.width,
    this.height,
    this.fit,
  });

  String? _fallbackFor(String p) {
    if (p.toLowerCase().endsWith('.png')) {
      return p.substring(0, p.length - 4) + '.jpg';
    }
    if (p.toLowerCase().endsWith('.jpg') || p.toLowerCase().endsWith('.jpeg')) {
      return p.replaceAll(RegExp(r'\.jpe?g'), '.png');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final fallback = _fallbackFor(path);
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stack) {
        if (fallback != null) {
          return Image.asset(
            fallback,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stack) {
              return Container(
                width: width,
                height: height,
                color: Colors.black12,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image),
              );
            },
          );
        }
        return Container(
          width: width,
          height: height,
          color: Colors.black12,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image),
        );
      },
    );
  }
}

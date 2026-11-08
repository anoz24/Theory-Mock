import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/attempt_model.dart';
import '../../../data/repositories/exams_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/exam_session_bloc.dart';

class ExamSessionScreen extends StatelessWidget {
  final String examId;
  final AttemptModel? attempt;

  const ExamSessionScreen({
    super.key,
    required this.examId,
    this.attempt,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);
    final uid = user?.id ?? '';

    return BlocProvider(
      create: (context) => ExamSessionBloc(
        examsRepository: context.read<ExamsRepository>(),
      )..add(ExamSessionStarted(
          examId: examId,
          uid: uid,
          initialAttempt: attempt,
        )),
      child: ExamSessionView(examId: examId),
    );
  }
}

class ExamSessionView extends StatelessWidget {
  final String examId;

  const ExamSessionView({super.key, required this.examId});

  String _formatTime(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void _confirmQuit(BuildContext context) {
    final bloc = context.read<ExamSessionBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quit Exam?'),
        content: const Text(
          'Are you sure you want to quit?\n\n'
          'Quitting will end your session immediately with a score of 0. '
          'Your attempt cannot be resumed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Stay in Exam'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.regulatoryRed,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              bloc.add(const ExamSessionQuitRequested());
            },
            child: const Text('Quit (Score 0)'),
          ),
        ],
      ),
    );
  }

  void _confirmFinish(BuildContext context, ExamSessionState state) {
    final bloc = context.read<ExamSessionBloc>();
    final answeredCount = state.answers.length;
    final totalCount = state.questions.length;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Submit Exam?'),
        content: Text(
          'You have answered $answeredCount of $totalCount questions.\n\n'
          'Once submitted, you will not be able to change your answers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Review Answers'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              bloc.add(const ExamSessionFinishRequested());
            },
            child: const Text('Submit Final'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExamSessionBloc, ExamSessionState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == ExamSessionStatus.finished ||
            state.status == ExamSessionStatus.timeout ||
            state.status == ExamSessionStatus.quit) {
          context.go('/exams/$examId/result');
        } else if (state.status == ExamSessionStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppTheme.regulatoryRed,
            ),
          );
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _confirmQuit(context);
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'Leave Exam',
              onPressed: () => _confirmQuit(context),
            ),
            title: BlocBuilder<ExamSessionBloc, ExamSessionState>(
              buildWhen: (prev, curr) =>
                  prev.remainingSeconds != curr.remainingSeconds,
              builder: (context, state) {
                final isUrgent = state.remainingSeconds < 60;
                final timerColor =
                    isUrgent ? AppTheme.roadwayAmber : AppTheme.textPrimary;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: timerColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(state.remainingSeconds),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: timerColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                );
              },
            ),
            actions: [
              BlocBuilder<ExamSessionBloc, ExamSessionState>(
                builder: (context, state) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TextButton(
                      onPressed: state.status == ExamSessionStatus.active
                          ? () => _confirmFinish(context, state)
                          : null,
                      child: const Text(
                        'Submit Exam',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: BlocBuilder<ExamSessionBloc, ExamSessionState>(
            builder: (context, state) {
              switch (state.status) {
                case ExamSessionStatus.initial:
                case ExamSessionStatus.loading:
                  return const Center(child: CircularProgressIndicator());

                case ExamSessionStatus.failure:
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.regulatoryRed.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.error_outline,
                              size: 28,
                              color: AppTheme.regulatoryRed,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Exam Session Error',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.errorMessage ?? 'Could not load exam session',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                case ExamSessionStatus.submitting:
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Submitting your answers...',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );

                case ExamSessionStatus.active:
                case ExamSessionStatus.finished:
                case ExamSessionStatus.timeout:
                case ExamSessionStatus.quit:
                  final q = state.currentQuestion;
                  if (q == null) {
                    return const Center(child: Text('No questions available'));
                  }

                  final selectedAnswer = state.answers[q.id];

                  return Column(
                    children: [
                      // Question Navigation Palette
                      Container(
                        height: 52,
                        decoration: const BoxDecoration(
                          color: AppTheme.surfaceColor,
                          border: Border(
                            bottom: BorderSide(color: AppTheme.hairlineColor),
                          ),
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          scrollDirection: Axis.horizontal,
                          itemCount: state.questions.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final question = state.questions[idx];
                            final isCurrent = idx == state.currentIndex;
                            final isAnswered =
                                state.answers.containsKey(question.id);

                            Color bg;
                            Color fg;
                            BorderSide border;

                            if (isCurrent) {
                              bg = AppTheme.primaryColor;
                              fg = Colors.white;
                              border =
                                  const BorderSide(color: AppTheme.primaryColor);
                            } else if (isAnswered) {
                              bg = AppTheme.signalEmerald
                                  .withValues(alpha: 0.12);
                              fg = AppTheme.signalEmerald;
                              border = const BorderSide(
                                  color: AppTheme.signalEmerald);
                            } else {
                              bg = AppTheme.raisedColor;
                              fg = AppTheme.textSecondary;
                              border =
                                  const BorderSide(color: AppTheme.hairlineColor);
                            }

                            return InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                context
                                    .read<ExamSessionBloc>()
                                    .add(ExamSessionIndexChanged(idx));
                              },
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.fromBorderSide(border),
                                ),
                                child: Center(
                                  child: Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      color: fg,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Question & Tactical Decision Pad
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Question ${state.currentIndex + 1} of ${state.questions.length}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textMuted,
                                      fontFeatures: [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  if (selectedAnswer != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.signalEmerald
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Answered',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.signalEmerald,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Text(
                                    q.text,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textPrimary,
                                      height: 1.45,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              const Text(
                                'Select your answer:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // True Option Card
                              _AnswerOptionCard(
                                label: 'True',
                                icon: Icons.check_circle_outline,
                                isSelected: selectedAnswer == true,
                                accentColor: AppTheme.signalEmerald,
                                onTap: () {
                                  context.read<ExamSessionBloc>().add(
                                        ExamSessionAnswerSelected(
                                          questionId: q.id,
                                          answer: true,
                                        ),
                                      );
                                },
                              ),
                              const SizedBox(height: 12),

                              // False Option Card
                              _AnswerOptionCard(
                                label: 'False',
                                icon: Icons.cancel_outlined,
                                isSelected: selectedAnswer == false,
                                accentColor: AppTheme.regulatoryRed,
                                onTap: () {
                                  context.read<ExamSessionBloc>().add(
                                        ExamSessionAnswerSelected(
                                          questionId: q.id,
                                          answer: false,
                                        ),
                                      );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Navigation Bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: const BoxDecoration(
                          color: AppTheme.surfaceColor,
                          border: Border(
                            top: BorderSide(color: AppTheme.hairlineColor),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton.icon(
                              onPressed: state.isFirstQuestion
                                  ? null
                                  : () {
                                      context.read<ExamSessionBloc>().add(
                                            ExamSessionIndexChanged(
                                              state.currentIndex - 1,
                                            ),
                                          );
                                    },
                              icon: const Icon(Icons.arrow_back, size: 16),
                              label: const Text('Back'),
                            ),
                            if (state.isLastQuestion)
                              FilledButton.icon(
                                onPressed: () =>
                                    _confirmFinish(context, state),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Finish Exam'),
                              )
                            else
                              FilledButton.icon(
                                onPressed: () {
                                  context.read<ExamSessionBloc>().add(
                                        ExamSessionIndexChanged(
                                          state.currentIndex + 1,
                                        ),
                                      );
                                },
                                icon: const Icon(Icons.arrow_forward, size: 16),
                                label: const Text('Next'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}

class _AnswerOptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _AnswerOptionCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected
          ? accentColor.withValues(alpha: 0.08)
          : AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? accentColor : AppTheme.hairlineColor,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? accentColor : AppTheme.textMuted,
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? accentColor : AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

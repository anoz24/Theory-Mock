import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/exam_model.dart';
import '../../../data/repositories/attempts_repository.dart';
import '../../../data/repositories/exams_repository.dart';
import '../bloc/live_monitor_bloc.dart';

class LiveMonitorScreen extends StatelessWidget {
  final String examId;
  final ExamModel? exam;

  const LiveMonitorScreen({
    super.key,
    required this.examId,
    this.exam,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LiveMonitorBloc(
        attemptsRepository: context.read<AttemptsRepository>(),
        examsRepository: context.read<ExamsRepository>(),
      )..add(LiveMonitorSubscriptionRequested(examId)),
      child: LiveMonitorView(
        examId: examId,
        examTitle: exam?.title,
      ),
    );
  }
}

class LiveMonitorView extends StatelessWidget {
  final String examId;
  final String? examTitle;

  const LiveMonitorView({
    super.key,
    required this.examId,
    this.examTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(examTitle != null ? 'Live: $examTitle' : 'Live Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment_outlined, size: 22),
            tooltip: 'View Results',
            onPressed: () {
              context.push(
                '/exams/$examId/results',
                extra: examTitle,
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<LiveMonitorBloc, LiveMonitorState>(
        builder: (context, state) {
          switch (state.status) {
            case LiveMonitorStatus.initial:
            case LiveMonitorStatus.loading:
              return const Center(child: CircularProgressIndicator());

            case LiveMonitorStatus.failure:
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
                          color: AppTheme.regulatoryRed.withValues(alpha: 0.1),
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
                        'Failed to load live monitor',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.errorMessage ?? 'An unknown error occurred',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: () => context
                            .read<LiveMonitorBloc>()
                            .add(LiveMonitorSubscriptionRequested(examId)),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );

            case LiveMonitorStatus.success:
              if (state.activeAttempts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppTheme.raisedColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.hairlineColor),
                          ),
                          child: const Icon(
                            Icons.sensors_outlined,
                            size: 32,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Active Candidates',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Candidates taking this exam will appear here in real-time.\n(Maximum 2 candidates concurrently)',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final selectedAttempt = state.selectedAttempt!;
              final questions = state.questions;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Signature Dual-Slot Telemetry Dock
                  Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.surfaceColor,
                      border: Border(
                        bottom: BorderSide(color: AppTheme.hairlineColor),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.signalEmerald,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Active candidates · ${state.activeAttempts.length} of 2 slots',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary,
                                fontFeatures: [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: state.activeAttempts.map((attempt) {
                            final isSelected = attempt.candidateId ==
                                selectedAttempt.candidateId;
                            return ChoiceChip(
                              avatar: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.hairlineColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    attempt.candidateName.isNotEmpty
                                        ? attempt.candidateName[0].toUpperCase()
                                        : 'C',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              label: Text(
                                '${attempt.candidateName} (Q${attempt.currentIndex + 1})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.textPrimary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                              selected: isSelected,
                              selectedColor:
                                  AppTheme.primaryColor.withValues(alpha: 0.12),
                              side: BorderSide(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.hairlineColor,
                              ),
                              onSelected: (_) {
                                context.read<LiveMonitorBloc>().add(
                                      LiveMonitorCandidateSelected(
                                        attempt.candidateId,
                                      ),
                                    );
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  // Candidate summary card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  selectedAttempt.candidateName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
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
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        size: 12,
                                        color: AppTheme.signalEmerald,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'In progress',
                                        style: TextStyle(
                                          color: AppTheme.signalEmerald,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Question ${selectedAttempt.currentIndex + 1} of ${questions.length}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontFeatures: [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: questions.isNotEmpty
                                    ? (selectedAttempt.answers.length /
                                            questions.length)
                                        .clamp(0.0, 1.0)
                                    : 0.0,
                                minHeight: 6,
                                backgroundColor: AppTheme.raisedColor,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Questions progress list
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: questions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final q = questions[index];
                        final hasAnswer =
                            selectedAttempt.answers.containsKey(q.id);
                        final candidateAnswer = selectedAttempt.answers[q.id];
                        final isCorrect = candidateAnswer == q.correctAnswer;
                        final isCurrent =
                            index == selectedAttempt.currentIndex;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isCurrent
                                  ? AppTheme.primaryColor
                                  : AppTheme.hairlineColor,
                              width: isCurrent ? 1.5 : 1.0,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: isCurrent
                                            ? AppTheme.primaryColor
                                            : AppTheme.raisedColor,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isCurrent
                                              ? AppTheme.primaryColor
                                              : AppTheme.hairlineColor,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isCurrent
                                                ? Colors.white
                                                : AppTheme.textPrimary,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures()
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Question ${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (hasAnswer)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isCorrect
                                              ? AppTheme.signalEmerald
                                                  .withValues(alpha: 0.12)
                                              : AppTheme.regulatoryRed
                                                  .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isCorrect
                                                  ? Icons.check
                                                  : Icons.close,
                                              size: 13,
                                              color: isCorrect
                                                  ? AppTheme.signalEmerald
                                                  : AppTheme.regulatoryRed,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isCorrect
                                                  ? 'Correct (+1)'
                                                  : 'Incorrect (0)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isCorrect
                                                    ? AppTheme.signalEmerald
                                                    : AppTheme.regulatoryRed,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (isCurrent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Answering now',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      )
                                    else
                                      const Text(
                                        'Not reached',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  q.text,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                    height: 1.35,
                                  ),
                                ),
                                if (hasAnswer) ...[
                                  const Divider(
                                    height: 16,
                                    color: AppTheme.hairlineColor,
                                  ),
                                  Row(
                                    children: [
                                      const Text(
                                        'Candidate: ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        candidateAnswer == true
                                            ? 'True'
                                            : 'False',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isCorrect
                                              ? AppTheme.signalEmerald
                                              : AppTheme.regulatoryRed,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Key: ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        q.correctAnswer == true
                                            ? 'True'
                                            : 'False',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
          }
        },
      ),
    );
  }
}

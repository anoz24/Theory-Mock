import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/exams_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../cubit/result_cubit.dart';
import '../cubit/result_state.dart';

class ResultScreen extends StatelessWidget {
  final String examId;

  const ResultScreen({super.key, required this.examId});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);
    final uid = user?.id ?? '';

    return BlocProvider(
      create: (context) => ResultCubit(
        examsRepository: context.read<ExamsRepository>(),
      )..loadResult(examId: examId, uid: uid),
      child: ResultView(examId: examId),
    );
  }
}

class ResultView extends StatelessWidget {
  final String examId;

  const ResultView({super.key, required this.examId});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Exam Result'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.home_outlined, size: 22),
              tooltip: 'Home',
              onPressed: () => context.go('/'),
            ),
          ],
        ),
        body: BlocBuilder<ResultCubit, ResultState>(
          builder: (context, state) {
            if (state.status == ResultStatus.loading ||
                state.status == ResultStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == ResultStatus.failure) {
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
                        'Failed to load result',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.errorMessage ?? 'An unexpected error occurred.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                        onPressed: () {
                          final uid =
                              context.read<AuthBloc>().state.user?.id ?? '';
                          context
                              .read<ResultCubit>()
                              .loadResult(examId: examId, uid: uid);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            final isTimeout = state.attemptStatus == 'timeout';
            final isFinished = state.attemptStatus == 'finished';

            final statusColor = isFinished
                ? AppTheme.signalEmerald
                : isTimeout
                    ? AppTheme.roadwayAmber
                    : AppTheme.regulatoryRed;

            final statusText = isFinished
                ? 'Completed'
                : isTimeout
                    ? 'Time Expired'
                    : 'Quit Early';

            final statusIcon = isFinished
                ? Icons.check_circle_outline
                : isTimeout
                    ? Icons.timer_off_outlined
                    : Icons.cancel_outlined;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status summary card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 24),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor.withValues(alpha: 0.12),
                              ),
                              child: Icon(
                                statusIcon,
                                size: 28,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              state.examTitle.isEmpty
                                  ? 'Theory Mock Exam'
                                  : state.examTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon,
                                      size: 14, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Signature Certificate Score Card
                    if (state.showScore) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 24),
                          child: Column(
                            children: [
                              const Text(
                                'Your Score',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${state.score}',
                                    style: const TextStyle(
                                      fontSize: 44,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                      letterSpacing: -1.0,
                                      fontFeatures: [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                  Text(
                                    ' / ${state.totalQuestions}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textMuted,
                                      fontFeatures: [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (state.totalQuestions > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.raisedColor,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: AppTheme.hairlineColor),
                                  ),
                                  child: Text(
                                    '${((state.score / state.totalQuestions) * 100).toStringAsFixed(0)}% Correct',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary,
                                      fontFeatures: [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Card(
                        child: const Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.visibility_off_outlined,
                                size: 32,
                                color: AppTheme.textMuted,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Submitted',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'The examiner has hidden the score for this exam.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Details metadata card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Column(
                          children: [
                            _DetailRow(
                              icon: Icons.person_outline,
                              label: 'Candidate',
                              value: state.candidateName,
                            ),
                            const Divider(
                              height: 20,
                              color: AppTheme.hairlineColor,
                            ),
                            _DetailRow(
                              icon: Icons.timer_outlined,
                              label: 'Duration',
                              value: state.formattedDuration,
                            ),
                            const Divider(
                              height: 20,
                              color: AppTheme.hairlineColor,
                            ),
                            _DetailRow(
                              icon: Icons.help_outline,
                              label: 'Total Questions',
                              value: '${state.totalQuestions}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Browse More Exams'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textMuted),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

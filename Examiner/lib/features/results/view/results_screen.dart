import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/attempts_repository.dart';
import '../bloc/results_bloc.dart';

class ResultsScreen extends StatelessWidget {
  final String examId;
  final String? examTitle;

  const ResultsScreen({
    super.key,
    required this.examId,
    this.examTitle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ResultsBloc(
        attemptsRepository: context.read<AttemptsRepository>(),
      )..add(ResultsSubscriptionRequested(examId)),
      child: ResultsView(examId: examId, examTitle: examTitle),
    );
  }
}

class ResultsView extends StatelessWidget {
  final String examId;
  final String? examTitle;

  const ResultsView({
    super.key,
    required this.examId,
    this.examTitle,
  });

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final remainingSecs = seconds % 60;
    return '${mins}m ${remainingSecs}s';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'finished':
        return AppTheme.signalEmerald;
      case 'timeout':
        return AppTheme.roadwayAmber;
      case 'quit':
        return AppTheme.regulatoryRed;
      default:
        return AppTheme.textMuted;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'finished':
        return 'Finished';
      case 'timeout':
        return 'Time expired';
      case 'quit':
        return 'Quit early';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = examTitle != null ? 'Results: $examTitle' : 'Exam Results';
    final dateFormat = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: BlocBuilder<ResultsBloc, ResultsState>(
        builder: (context, state) {
          switch (state.status) {
            case ResultsStatus.initial:
            case ResultsStatus.loading:
              return const Center(child: CircularProgressIndicator());

            case ResultsStatus.failure:
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
                        'Failed to load results',
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
                            .read<ResultsBloc>()
                            .add(ResultsSubscriptionRequested(examId)),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );

            case ResultsStatus.success:
              if (state.attempts.isEmpty) {
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
                            Icons.fact_check_outlined,
                            size: 32,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Completed Attempts',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Results will appear here as soon as candidates submit or finish their exams.',
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

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.attempts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final attempt = state.attempts[index];
                  final statusColor = _statusColor(attempt.status);

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  attempt.candidateName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _statusLabel(attempt.status),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _MetricTile(
                                icon: Icons.stars_outlined,
                                label: 'Score',
                                value: '${attempt.score} pts',
                              ),
                              const SizedBox(width: 28),
                              _MetricTile(
                                icon: Icons.timer_outlined,
                                label: 'Time Taken',
                                value: _formatDuration(attempt.durationSec),
                              ),
                            ],
                          ),
                          const Divider(
                            height: 24,
                            color: AppTheme.hairlineColor,
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Submitted: ${dateFormat.format(attempt.startedAt)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  fontFeatures: [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
          }
        },
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 2),
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
        ),
      ],
    );
  }
}

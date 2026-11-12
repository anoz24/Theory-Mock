import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/exam_model.dart';
import '../../../data/repositories/exams_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/exam_entry_bloc.dart';

class ExamDetailScreen extends StatelessWidget {
  final String examId;
  final ExamModel? exam;

  const ExamDetailScreen({
    super.key,
    required this.examId,
    this.exam,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);
    final uid = user?.id ?? '';

    return BlocProvider(
      create: (context) => ExamEntryBloc(
        examsRepository: context.read<ExamsRepository>(),
      )..add(ExamEntrySubscriptionRequested(examId: examId, uid: uid)),
      child: ExamDetailView(
        examId: examId,
        fallbackExam: exam,
      ),
    );
  }
}

class ExamDetailView extends StatelessWidget {
  final String examId;
  final ExamModel? fallbackExam;

  const ExamDetailView({
    super.key,
    required this.examId,
    this.fallbackExam,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);
    final dateFormat = DateFormat.yMMMd().add_jm();

    return BlocListener<ExamEntryBloc, ExamEntryState>(
      listenWhen: (prev, curr) => prev.admissionStatus != curr.admissionStatus,
      listener: (context, state) {
        switch (state.admissionStatus) {
          case ExamAdmissionStatus.admitted:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Admitted. Starting your exam session...'),
                backgroundColor: AppTheme.signalEmerald,
              ),
            );
            if (context.mounted) {
              context.push(
                '/exams/$examId/session',
                extra: state.admittedAttempt,
              );
            }
          case ExamAdmissionStatus.full:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'This exam is currently full (2/2 active candidates). Please wait for a slot to open.',
                ),
                backgroundColor: AppTheme.roadwayAmber,
              ),
            );
          case ExamAdmissionStatus.alreadyTaken:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Entry refused: You have already attempted this exam. Each candidate is allowed only one attempt.',
                ),
                backgroundColor: AppTheme.regulatoryRed,
              ),
            );
          case ExamAdmissionStatus.error:
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppTheme.regulatoryRed,
                ),
              );
            }
          case ExamAdmissionStatus.idle:
          case ExamAdmissionStatus.starting:
            break;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Exam Overview'),
        ),
        body: BlocBuilder<ExamEntryBloc, ExamEntryState>(
          builder: (context, state) {
            final exam = state.exam ?? fallbackExam;

            if (exam == null && state.status == ExamEntryStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (exam == null) {
              return const Center(child: Text('Exam not found'));
            }

            final isFull = exam.isFull;
            final liveSlots = exam.liveSlotCount;
            final availableSlots = 2 - liveSlots;
            final buttonState = state.buttonState;
            final isStarting =
                state.admissionStatus == ExamAdmissionStatus.starting;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exam.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _DetailRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Scheduled for',
                            value: dateFormat.format(exam.date),
                          ),
                          const SizedBox(height: 14),
                          _DetailRow(
                            icon: Icons.timer_outlined,
                            label: 'Duration',
                            value: '${exam.durationMin} minutes',
                          ),
                          const SizedBox(height: 14),
                          _DetailRow(
                            icon: exam.showScore
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            label: 'Score visibility',
                            value: exam.showScore
                                ? 'Score displayed upon completion'
                                : 'Score hidden by examiner',
                          ),
                          const Divider(
                            height: 28,
                            color: AppTheme.hairlineColor,
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isFull
                                      ? AppTheme.regulatoryRed
                                      : AppTheme.signalEmerald,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Live slot availability',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (isFull
                                          ? AppTheme.regulatoryRed
                                          : AppTheme.signalEmerald)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isFull
                                      ? 'Full (2/2 active)'
                                      : '$availableSlots / 2 slots open',
                                  style: TextStyle(
                                    color: isFull
                                        ? AppTheme.regulatoryRed
                                        : AppTheme.signalEmerald,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.raisedColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.hairlineColor),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Exam guidelines',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          '• Maximum 2 candidates can take this exam simultaneously.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '• Once admitted, your timer starts automatically.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '• Each candidate is allowed only one attempt per exam.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '• All questions are True / False.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Dynamic Action Button based on state
                  if (buttonState == ExamButtonState.alreadyTaken) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: null,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Already Taken (1 attempt limit)'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You have already taken this exam.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ] else if (buttonState == ExamButtonState.full) ...[
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppTheme.roadwayAmber,
                      ),
                      onPressed: null,
                      icon: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      label: const Text('Exam Full (Waiting for open slot...)'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This button will automatically update as soon as an active candidate finishes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: isStarting
                          ? null
                          : () {
                              context.read<ExamEntryBloc>().add(
                                    ExamEntryStartAttemptRequested(
                                      examId: examId,
                                      uid: user?.id ?? '',
                                      candidateName:
                                          user?.displayName.isNotEmpty == true
                                              ? user!.displayName
                                              : 'Candidate',
                                    ),
                                  );
                            },
                      icon: isStarting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow, size: 20),
                      label: Text(
                        isStarting ? 'Entering Exam...' : 'Start Exam',
                      ),
                    ),
                  ],
                ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
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

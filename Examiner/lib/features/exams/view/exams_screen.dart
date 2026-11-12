import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/exam_model.dart';
import '../../../data/repositories/exams_repository.dart';
import '../bloc/exams_bloc.dart';

class ExamsScreen extends StatelessWidget {
  final String categoryId;
  final CategoryModel? category;

  const ExamsScreen({
    super.key,
    required this.categoryId,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExamsBloc(
        examsRepository: context.read<ExamsRepository>(),
      )..add(ExamsSubscriptionRequested(categoryId)),
      child: ExamsView(
        categoryId: categoryId,
        categoryName: category?.name,
      ),
    );
  }
}

class ExamsView extends StatelessWidget {
  final String categoryId;
  final String? categoryName;

  const ExamsView({
    super.key,
    required this.categoryId,
    this.categoryName,
  });

  void _confirmDelete(BuildContext context, ExamModel exam) {
    final bloc = context.read<ExamsBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Exam?'),
        content: Text(
          'Are you sure you want to delete "${exam.title}"?\n'
          'All associated questions will also be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.regulatoryRed,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              bloc.add(ExamDeleteRequested(exam.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted "${exam.title}"')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = categoryName != null ? '$categoryName Exams' : 'Exams';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(
            '/categories/$categoryId/exams/create',
            extra: categoryName,
          );
        },
        icon: const Icon(Icons.add, size: 20),
        label: const Text('New Exam'),
      ),
      body: BlocConsumer<ExamsBloc, ExamsState>(
        listenWhen: (prev, curr) =>
            prev.actionErrorMessage != curr.actionErrorMessage &&
            curr.actionErrorMessage != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionErrorMessage!),
              backgroundColor: AppTheme.regulatoryRed,
            ),
          );
        },
        builder: (context, state) {
          switch (state.status) {
            case ExamsStatus.initial:
            case ExamsStatus.loading:
              return const Center(child: CircularProgressIndicator());

            case ExamsStatus.failure:
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
                        'Failed to load exams',
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
                            .read<ExamsBloc>()
                            .add(ExamsSubscriptionRequested(categoryId)),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );

            case ExamsStatus.success:
              if (state.exams.isEmpty) {
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
                            Icons.assignment_outlined,
                            size: 32,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No exams in this category',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create an exam with True/False questions for candidates to take.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () {
                            context.push(
                              '/categories/$categoryId/exams/create',
                              extra: categoryName,
                            );
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create Exam'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final dateFormat = DateFormat.yMMMd().add_jm();

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: state.exams.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final exam = state.exams[index];
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        context.push(
                          '/exams/${exam.id}/monitor',
                          extra: exam,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    exam.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppTheme.regulatoryRed,
                                    size: 20,
                                  ),
                                  tooltip: 'Delete Exam',
                                  onPressed: () => _confirmDelete(context, exam),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  dateFormat.format(exam.date),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Chip(
                                  avatar: const Icon(
                                    Icons.timer_outlined,
                                    size: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                  label: Text('${exam.durationMin} min'),
                                  visualDensity: VisualDensity.compact,
                                ),
                                Chip(
                                  avatar: Icon(
                                    exam.showScore
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                  label: Text(
                                    exam.showScore
                                        ? 'Score visible'
                                        : 'Score hidden',
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ],
                        ),
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

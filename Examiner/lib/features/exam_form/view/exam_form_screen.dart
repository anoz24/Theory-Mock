import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/exams_repository.dart';
import '../bloc/exam_form_bloc.dart';

class ExamFormScreen extends StatelessWidget {
  final String categoryId;
  final String? categoryName;

  const ExamFormScreen({
    super.key,
    required this.categoryId,
    this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExamFormBloc(
        examsRepository: context.read<ExamsRepository>(),
        categoryId: categoryId,
      ),
      child: ExamFormView(categoryName: categoryName),
    );
  }
}

class ExamFormView extends StatelessWidget {
  final String? categoryName;

  const ExamFormView({super.key, this.categoryName});

  Future<void> _pickDateTime(BuildContext context, DateTime currentDate) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentDate),
    );

    if (pickedTime == null || !context.mounted) return;

    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    context.read<ExamFormBloc>().add(ExamFormDateChanged(newDateTime));
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();

    return BlocListener<ExamFormBloc, ExamFormState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == ExamFormStatus.success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exam created successfully')),
          );
        } else if (state.status == ExamFormStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppTheme.regulatoryRed,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Exam'),
          bottom: categoryName != null
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(24),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, left: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Category: $categoryName',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        ),
        body: BlocBuilder<ExamFormBloc, ExamFormState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Exam Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: state.title,
                            decoration: const InputDecoration(
                              labelText: 'Exam Title *',
                              hintText: 'e.g., Road Safety Mock 1',
                              prefixIcon: Icon(Icons.title, size: 20),
                            ),
                            onChanged: (value) => context
                                .read<ExamFormBloc>()
                                .add(ExamFormTitleChanged(value)),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _pickDateTime(context, state.date),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Scheduled Date & Time',
                                prefixIcon: Icon(Icons.calendar_today_outlined,
                                    size: 20),
                                suffixIcon: Icon(Icons.arrow_drop_down),
                              ),
                              child: Text(
                                dateFormat.format(state.date),
                                style: const TextStyle(
                                  fontFeatures: [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: state.durationMin.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Duration (minutes) *',
                              hintText: 'e.g., 30',
                              prefixIcon: Icon(Icons.timer_outlined, size: 20),
                            ),
                            onChanged: (value) {
                              final min = int.tryParse(value) ?? 0;
                              context
                                  .read<ExamFormBloc>()
                                  .add(ExamFormDurationChanged(min));
                            },
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeTrackColor: AppTheme.primaryColor,
                            title: const Text(
                              'Show Final Score to Candidates',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            subtitle: const Text(
                              'When disabled, score is visible only to examiners.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            value: state.showScore,
                            onChanged: (value) => context
                                .read<ExamFormBloc>()
                                .add(ExamFormShowScoreToggled(value)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Questions (${state.questions.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        onPressed: () => context
                            .read<ExamFormBloc>()
                            .add(const ExamFormQuestionAdded()),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Question'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(state.questions.length, (index) {
                    final q = state.questions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppTheme.raisedColor,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: AppTheme.hairlineColor),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                          fontFeatures: [
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (state.questions.length > 1)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppTheme.regulatoryRed,
                                        size: 18,
                                      ),
                                      tooltip: 'Remove Question',
                                      onPressed: () => context
                                          .read<ExamFormBloc>()
                                          .add(ExamFormQuestionRemoved(index)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                initialValue: q.text,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Question Statement *',
                                  hintText:
                                      'e.g., Drivers must always yield to pedestrians at zebra crossings.',
                                ),
                                onChanged: (value) => context
                                    .read<ExamFormBloc>()
                                    .add(ExamFormQuestionTextChanged(
                                      index: index,
                                      text: value,
                                    )),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  const Text(
                                    'Correct Answer:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  SegmentedButton<bool>(
                                    style: SegmentedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      selectedBackgroundColor:
                                          AppTheme.primaryColor.withValues(alpha: 0.12),
                                      selectedForegroundColor:
                                          AppTheme.primaryColor,
                                    ),
                                    segments: const [
                                      ButtonSegment(
                                        value: true,
                                        label: Text('True'),
                                        icon: Icon(Icons.check, size: 16),
                                      ),
                                      ButtonSegment(
                                        value: false,
                                        label: Text('False'),
                                        icon: Icon(Icons.close, size: 16),
                                      ),
                                    ],
                                    selected: {q.correctAnswer},
                                    onSelectionChanged: (selected) {
                                      context.read<ExamFormBloc>().add(
                                            ExamFormQuestionAnswerChanged(
                                              index: index,
                                              correctAnswer: selected.first,
                                            ),
                                          );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: state.status == ExamFormStatus.submitting
                        ? null
                        : () => context
                            .read<ExamFormBloc>()
                            .add(const ExamFormSubmitted()),
                    icon: state.status == ExamFormStatus.submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(
                      state.status == ExamFormStatus.submitting
                          ? 'Saving Exam...'
                          : 'Save Exam',
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

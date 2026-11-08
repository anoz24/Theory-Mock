import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/categories_repository.dart';
import '../../../data/repositories/exams_repository.dart';
import '../bloc/browse_bloc.dart';

class CategoryExamsScreen extends StatelessWidget {
  final String categoryId;
  final CategoryModel? category;

  const CategoryExamsScreen({
    super.key,
    required this.categoryId,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BrowseBloc(
        categoriesRepository: context.read<CategoriesRepository>(),
        examsRepository: context.read<ExamsRepository>(),
      )..add(BrowseExamsSubscriptionRequested(categoryId)),
      child: CategoryExamsView(
        categoryId: categoryId,
        categoryName: category?.name,
      ),
    );
  }
}

class CategoryExamsView extends StatelessWidget {
  final String categoryId;
  final String? categoryName;

  const CategoryExamsView({
    super.key,
    required this.categoryId,
    this.categoryName,
  });

  Future<void> _pickDate(BuildContext context, DateTime? currentDate) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null && context.mounted) {
      context.read<BrowseBloc>().add(BrowseDateFilterChanged(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = categoryName != null ? '$categoryName Exams' : 'Exams';
    final dateFormat = DateFormat.yMMMd().add_jm();
    final filterFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        children: [
          // Date Filter Bar
          BlocBuilder<BrowseBloc, BrowseState>(
            buildWhen: (prev, curr) => prev.selectedDate != curr.selectedDate,
            builder: (context, state) {
              final selectedDate = state.selectedDate;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceColor,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.hairlineColor),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.filter_list,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    if (selectedDate == null) ...[
                      const Text(
                        'All dates',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                        onPressed: () => _pickDate(context, null),
                        icon: const Icon(Icons.calendar_today, size: 14),
                        label: const Text('Filter Date'),
                      ),
                    ] else ...[
                      Chip(
                        avatar: const Icon(Icons.event, size: 14),
                        label: Text(filterFormat.format(selectedDate)),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () {
                          context
                              .read<BrowseBloc>()
                              .add(const BrowseDateFilterChanged(null));
                        },
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _pickDate(context, selectedDate),
                        child: const Text('Change Date'),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          // Exams list
          Expanded(
            child: BlocBuilder<BrowseBloc, BrowseState>(
              builder: (context, state) {
                switch (state.examsStatus) {
                  case BrowseStatus.initial:
                  case BrowseStatus.loading:
                    return const Center(child: CircularProgressIndicator());

                  case BrowseStatus.failure:
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
                              'Failed to load exams',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.errorMessage ??
                                  'Please check your connection',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              onPressed: () => context.read<BrowseBloc>().add(
                                    BrowseExamsSubscriptionRequested(
                                        categoryId),
                                  ),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );

                  case BrowseStatus.success:
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
                                  border:
                                      Border.all(color: AppTheme.hairlineColor),
                                ),
                                child: const Icon(
                                  Icons.assignment_outlined,
                                  size: 32,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                state.selectedDate == null
                                    ? 'No exams in this category'
                                    : 'No exams on ${filterFormat.format(state.selectedDate!)}',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              if (state.selectedDate != null)
                                TextButton.icon(
                                  onPressed: () => context
                                      .read<BrowseBloc>()
                                      .add(const BrowseDateFilterChanged(null)),
                                  icon: const Icon(Icons.clear, size: 16),
                                  label: const Text('Clear date filter'),
                                ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.exams.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final exam = state.exams[index];
                        final isFull = exam.isFull;
                        final availableSlots = 2 - exam.liveSlotCount;

                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              context.push(
                                '/exams/${exam.id}',
                                extra: exam,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      const Icon(
                                        Icons.chevron_right,
                                        size: 20,
                                        color: AppTheme.textMuted,
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
                                          isFull
                                              ? Icons.group
                                              : Icons.group_outlined,
                                          size: 14,
                                          color: isFull
                                              ? AppTheme.regulatoryRed
                                              : AppTheme.signalEmerald,
                                        ),
                                        label: Text(
                                          isFull
                                              ? 'Full (2/2 active)'
                                              : '$availableSlots slot(s) available',
                                          style: TextStyle(
                                            color: isFull
                                                ? AppTheme.regulatoryRed
                                                : AppTheme.signalEmerald,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        backgroundColor: isFull
                                            ? AppTheme.regulatoryRed
                                                .withValues(alpha: 0.1)
                                            : AppTheme.signalEmerald
                                                .withValues(alpha: 0.1),
                                        side: BorderSide.none,
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
          ),
        ],
      ),
    );
  }
}

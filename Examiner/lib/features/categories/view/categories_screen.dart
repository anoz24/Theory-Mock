import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/categories_repository.dart';
import '../bloc/categories_bloc.dart';
import 'widgets/add_category_sheet.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CategoriesBloc(
        categoriesRepository: context.read<CategoriesRepository>(),
      )..add(const CategoriesSubscriptionRequested()),
      child: const CategoriesView(),
    );
  }
}

class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key});

  void _showAddCategorySheet(BuildContext context) {
    final bloc = context.read<CategoriesBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (bottomSheetContext) => BlocProvider.value(
        value: bloc,
        child: const AddCategorySheet(),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CategoryModel category) {
    final bloc = context.read<CategoriesBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
          'Are you sure you want to delete "${category.name}"?\n'
          'All exams and questions inside this category will also be permanently deleted.',
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
              bloc.add(CategoryDeleteRequested(category));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted "${category.name}"')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Categories'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategorySheet(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('New Category'),
      ),
      body: BlocConsumer<CategoriesBloc, CategoriesState>(
        listenWhen: (prev, curr) =>
            prev.actionErrorMessage != curr.actionErrorMessage &&
            curr.actionErrorMessage != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionErrorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
        builder: (context, state) {
          switch (state.status) {
            case CategoriesStatus.initial:
            case CategoriesStatus.loading:
              return const Center(child: CircularProgressIndicator());

            case CategoriesStatus.failure:
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
                        'Failed to load categories',
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
                            .read<CategoriesBloc>()
                            .add(const CategoriesSubscriptionRequested()),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );

            case CategoriesStatus.success:
              if (state.categories.isEmpty) {
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
                            Icons.folder_open_outlined,
                            size: 32,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No categories yet',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a category to start adding theory exams.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => _showAddCategorySheet(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Category'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.82,
                ),
                itemCount: state.categories.length,
                itemBuilder: (context, index) {
                  final category = state.categories[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        context.push(
                          '/categories/${category.id}/exams',
                          extra: category,
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (category.imageBase64.isNotEmpty)
                                  Image.memory(
                                    base64Decode(category.imageBase64),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: AppTheme.raisedColor,
                                      child: const Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 32,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  )
                                else if (category.imageUrl.isNotEmpty)
                                  Image.network(
                                    category.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: AppTheme.raisedColor,
                                      child: const Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 32,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: AppTheme.raisedColor,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                else
                                  Container(
                                    color: AppTheme.raisedColor,
                                    child: const Icon(
                                      Icons.directions_car_outlined,
                                      size: 36,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                PositionActionDelete(
                                  onDelete: () =>
                                      _confirmDelete(context, category),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: AppTheme.surfaceColor,
                              border: Border(
                                top: BorderSide(color: AppTheme.hairlineColor),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                              vertical: 12.0,
                            ),
                            child: Text(
                              category.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
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

class PositionActionDelete extends StatelessWidget {
  final VoidCallback onDelete;

  const PositionActionDelete({
    super.key,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppTheme.hairlineColor),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onDelete,
          child: const Padding(
            padding: EdgeInsets.all(6.0),
            child: Icon(
              Icons.delete_outline,
              color: AppTheme.regulatoryRed,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

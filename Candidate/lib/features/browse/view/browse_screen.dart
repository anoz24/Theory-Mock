import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/categories_repository.dart';
import '../../../data/repositories/exams_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/browse_bloc.dart';

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BrowseBloc(
        categoriesRepository: context.read<CategoriesRepository>(),
        examsRepository: context.read<ExamsRepository>(),
      )..add(const BrowseCategoriesSubscriptionRequested()),
      child: const BrowseView(),
    );
  }
}

class BrowseView extends StatelessWidget {
  const BrowseView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Exam Categories'),
            if (user != null && user.displayName.isNotEmpty)
              Text(
                'Hi, ${user.displayName}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Sign Out',
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: BlocBuilder<BrowseBloc, BrowseState>(
        builder: (context, state) {
          switch (state.categoriesStatus) {
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
                        state.errorMessage ?? 'Please check your connection',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: () => context
                            .read<BrowseBloc>()
                            .add(const BrowseCategoriesSubscriptionRequested()),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );

            case BrowseStatus.success:
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
                          'No categories available',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Categories will appear here once examiners create them.',
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

              return GridView.builder(
                padding: const EdgeInsets.all(16),
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

import 'package:examiner/core/theme/app_theme.dart';
import 'package:examiner/data/models/category_model.dart';
import 'package:examiner/data/repositories/categories_repository.dart';
import 'package:examiner/features/categories/view/categories_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoriesRepository extends Mock implements CategoriesRepository {}

void main() {
  late MockCategoriesRepository mockRepository;

  setUp(() {
    mockRepository = MockCategoriesRepository();
  });

  testWidgets('CategoriesScreen displays empty state when no categories', (WidgetTester tester) async {
    when(() => mockRepository.getCategories())
        .thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(
      RepositoryProvider<CategoriesRepository>.value(
        value: mockRepository,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CategoriesScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Exam Categories'), findsOneWidget);
    expect(find.text('No categories yet'), findsOneWidget);
  });

  testWidgets('CategoriesScreen displays category list when categories exist', (WidgetTester tester) async {
    const sampleCategory = CategoryModel(
      id: 'cat_1',
      name: 'Road Signs',
      imageUrl: '',
    );
    when(() => mockRepository.getCategories())
        .thenAnswer((_) => Stream.value([sampleCategory]));

    await tester.pumpWidget(
      RepositoryProvider<CategoriesRepository>.value(
        value: mockRepository,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CategoriesScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Road Signs'), findsOneWidget);
  });
}

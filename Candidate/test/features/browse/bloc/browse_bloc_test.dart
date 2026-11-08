import 'package:bloc_test/bloc_test.dart';
import 'package:candidate/data/models/category_model.dart';
import 'package:candidate/data/models/exam_model.dart';
import 'package:candidate/data/repositories/categories_repository.dart';
import 'package:candidate/data/repositories/exams_repository.dart';
import 'package:candidate/features/browse/bloc/browse_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoriesRepository extends Mock implements CategoriesRepository {}

class MockExamsRepository extends Mock implements ExamsRepository {}

void main() {
  late MockCategoriesRepository mockCategoriesRepository;
  late MockExamsRepository mockExamsRepository;

  const sampleCategory = CategoryModel(
    id: 'cat_1',
    name: 'Road Signs',
  );

  final sampleExam = ExamModel(
    id: 'exam_1',
    categoryId: 'cat_1',
    title: 'Theory Test 1',
    date: DateTime(2026, 11, 8, 14, 0),
    durationMin: 30,
  );

  setUp(() {
    mockCategoriesRepository = MockCategoriesRepository();
    mockExamsRepository = MockExamsRepository();
  });

  group('BrowseBloc', () {
    test('initial state is correct', () {
      final bloc = BrowseBloc(
        categoriesRepository: mockCategoriesRepository,
        examsRepository: mockExamsRepository,
      );
      expect(bloc.state, equals(const BrowseState()));
    });

    blocTest<BrowseBloc, BrowseState>(
      'emits categories when BrowseCategoriesSubscriptionRequested succeeds',
      build: () {
        when(() => mockCategoriesRepository.getCategories())
            .thenAnswer((_) => Stream.value([sampleCategory]));
        return BrowseBloc(
          categoriesRepository: mockCategoriesRepository,
          examsRepository: mockExamsRepository,
        );
      },
      act: (bloc) => bloc.add(const BrowseCategoriesSubscriptionRequested()),
      expect: () => [
        const BrowseState(categoriesStatus: BrowseStatus.loading),
        const BrowseState(
          categoriesStatus: BrowseStatus.success,
          categories: [sampleCategory],
        ),
      ],
    );

    blocTest<BrowseBloc, BrowseState>(
      'emits exams when BrowseExamsSubscriptionRequested succeeds',
      build: () {
        when(() => mockExamsRepository.getExamsForCategory(
              'cat_1',
              dateFilter: any(named: 'dateFilter'),
            )).thenAnswer((_) => Stream.value([sampleExam]));
        return BrowseBloc(
          categoriesRepository: mockCategoriesRepository,
          examsRepository: mockExamsRepository,
        );
      },
      act: (bloc) => bloc.add(const BrowseExamsSubscriptionRequested('cat_1')),
      expect: () => [
        const BrowseState(
          examsStatus: BrowseStatus.loading,
          selectedCategoryId: 'cat_1',
        ),
        BrowseState(
          examsStatus: BrowseStatus.success,
          selectedCategoryId: 'cat_1',
          exams: [sampleExam],
        ),
      ],
    );

    blocTest<BrowseBloc, BrowseState>(
      'updates filter and reloads exams on BrowseDateFilterChanged',
      build: () {
        when(() => mockExamsRepository.getExamsForCategory(
              'cat_1',
              dateFilter: any(named: 'dateFilter'),
            )).thenAnswer((_) => Stream.value([sampleExam]));
        return BrowseBloc(
          categoriesRepository: mockCategoriesRepository,
          examsRepository: mockExamsRepository,
        );
      },
      seed: () => const BrowseState(
        selectedCategoryId: 'cat_1',
        examsStatus: BrowseStatus.success,
      ),
      act: (bloc) => bloc.add(BrowseDateFilterChanged(DateTime(2026, 11, 8))),
      expect: () => [
        BrowseState(
          selectedCategoryId: 'cat_1',
          selectedDate: DateTime(2026, 11, 8),
          examsStatus: BrowseStatus.success,
        ),
        BrowseState(
          selectedCategoryId: 'cat_1',
          selectedDate: DateTime(2026, 11, 8),
          examsStatus: BrowseStatus.loading,
        ),
        BrowseState(
          selectedCategoryId: 'cat_1',
          selectedDate: DateTime(2026, 11, 8),
          examsStatus: BrowseStatus.success,
          exams: [sampleExam],
        ),
      ],
    );
  });
}


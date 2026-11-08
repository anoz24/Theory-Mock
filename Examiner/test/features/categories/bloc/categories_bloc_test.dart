import 'dart:io';
import 'package:bloc_test/bloc_test.dart';
import 'package:examiner/data/models/category_model.dart';
import 'package:examiner/data/repositories/categories_repository.dart';
import 'package:examiner/features/categories/bloc/categories_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoriesRepository extends Mock implements CategoriesRepository {}

class FakeFile extends Fake implements File {}

void main() {
  late MockCategoriesRepository mockRepository;
  const sampleCategory = CategoryModel(
    id: 'cat_1',
    name: 'Road Signs',
    imageUrl: 'https://example.com/signs.jpg',
  );

  setUpAll(() {
    registerFallbackValue(FakeFile());
  });

  setUp(() {
    mockRepository = MockCategoriesRepository();
  });

  group('CategoriesBloc', () {
    test('initial state is correct', () {
      final bloc = CategoriesBloc(categoriesRepository: mockRepository);
      expect(bloc.state, equals(const CategoriesState()));
    });

    blocTest<CategoriesBloc, CategoriesState>(
      'emits [loading, success] when CategoriesSubscriptionRequested succeeds',
      build: () {
        when(() => mockRepository.getCategories())
            .thenAnswer((_) => Stream.value([sampleCategory]));
        return CategoriesBloc(categoriesRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const CategoriesSubscriptionRequested()),
      expect: () => [
        const CategoriesState(status: CategoriesStatus.loading),
        const CategoriesState(
          status: CategoriesStatus.success,
          categories: [sampleCategory],
        ),
      ],
    );

    blocTest<CategoriesBloc, CategoriesState>(
      'emits [loading, failure] when CategoriesSubscriptionRequested fails',
      build: () {
        when(() => mockRepository.getCategories())
            .thenAnswer((_) => Stream.error(Exception('Firestore error')));
        return CategoriesBloc(categoriesRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const CategoriesSubscriptionRequested()),
      expect: () => [
        const CategoriesState(status: CategoriesStatus.loading),
        isA<CategoriesState>()
            .having((s) => s.status, 'status', CategoriesStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', contains('Firestore error')),
      ],
    );

    blocTest<CategoriesBloc, CategoriesState>(
      'emits [loading, success] when CategoryCreateRequested succeeds',
      build: () {
        when(() => mockRepository.createCategory(
              name: any(named: 'name'),
              imageFile: any(named: 'imageFile'),
            )).thenAnswer((_) async => sampleCategory);
        return CategoriesBloc(categoriesRepository: mockRepository);
      },
      act: (bloc) => bloc.add(CategoryCreateRequested(
        name: 'Road Signs',
        imageFile: File('dummy_path'),
      )),
      expect: () => [
        const CategoriesState(actionStatus: CategoryActionStatus.loading),
        const CategoriesState(actionStatus: CategoryActionStatus.success),
      ],
    );

    blocTest<CategoriesBloc, CategoriesState>(
      'emits [loading, failure] when CategoryCreateRequested fails',
      build: () {
        when(() => mockRepository.createCategory(
              name: any(named: 'name'),
              imageFile: any(named: 'imageFile'),
            )).thenThrow(Exception('Upload failed'));
        return CategoriesBloc(categoriesRepository: mockRepository);
      },
      act: (bloc) => bloc.add(CategoryCreateRequested(
        name: 'Road Signs',
        imageFile: File('dummy_path'),
      )),
      expect: () => [
        const CategoriesState(actionStatus: CategoryActionStatus.loading),
        isA<CategoriesState>()
            .having((s) => s.actionStatus, 'actionStatus', CategoryActionStatus.failure)
            .having((s) => s.actionErrorMessage, 'actionErrorMessage', contains('Upload failed')),
      ],
    );

    blocTest<CategoriesBloc, CategoriesState>(
      'calls deleteCategory when CategoryDeleteRequested is added',
      build: () {
        when(() => mockRepository.deleteCategory(any()))
            .thenAnswer((_) async {});
        return CategoriesBloc(categoriesRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const CategoryDeleteRequested(sampleCategory)),
      verify: (_) {
        verify(() => mockRepository.deleteCategory(sampleCategory.id)).called(1);
      },
    );
  });
}

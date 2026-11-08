import 'package:bloc_test/bloc_test.dart';
import 'package:examiner/data/models/exam_model.dart';
import 'package:examiner/data/repositories/exams_repository.dart';
import 'package:examiner/features/exams/bloc/exams_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExamsRepository extends Mock implements ExamsRepository {}

void main() {
  late MockExamsRepository mockRepository;
  final sampleExam = ExamModel(
    id: 'exam_1',
    categoryId: 'cat_1',
    title: 'Basic Driving Theory',
    date: DateTime(2026, 12, 1, 10, 0),
    durationMin: 30,
    showScore: true,
  );

  setUp(() {
    mockRepository = MockExamsRepository();
  });

  group('ExamsBloc', () {
    test('initial state is correct', () {
      final bloc = ExamsBloc(examsRepository: mockRepository);
      expect(bloc.state, equals(const ExamsState()));
    });

    blocTest<ExamsBloc, ExamsState>(
      'emits [loading, success] when ExamsSubscriptionRequested succeeds',
      build: () {
        when(() => mockRepository.getExamsForCategory('cat_1'))
            .thenAnswer((_) => Stream.value([sampleExam]));
        return ExamsBloc(examsRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const ExamsSubscriptionRequested('cat_1')),
      expect: () => [
        const ExamsState(status: ExamsStatus.loading),
        ExamsState(
          status: ExamsStatus.success,
          exams: [sampleExam],
        ),
      ],
    );

    blocTest<ExamsBloc, ExamsState>(
      'emits [loading, failure] when ExamsSubscriptionRequested fails',
      build: () {
        when(() => mockRepository.getExamsForCategory('cat_1'))
            .thenAnswer((_) => Stream.error(Exception('Failed to fetch exams')));
        return ExamsBloc(examsRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const ExamsSubscriptionRequested('cat_1')),
      expect: () => [
        const ExamsState(status: ExamsStatus.loading),
        isA<ExamsState>()
            .having((s) => s.status, 'status', ExamsStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', contains('Failed to fetch exams')),
      ],
    );

    blocTest<ExamsBloc, ExamsState>(
      'calls deleteExam when ExamDeleteRequested is added',
      build: () {
        when(() => mockRepository.deleteExam('exam_1'))
            .thenAnswer((_) async {});
        return ExamsBloc(examsRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const ExamDeleteRequested('exam_1')),
      verify: (_) {
        verify(() => mockRepository.deleteExam('exam_1')).called(1);
      },
    );
  });
}


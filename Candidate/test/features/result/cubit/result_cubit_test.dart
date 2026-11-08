import 'package:bloc_test/bloc_test.dart';
import 'package:candidate/data/models/attempt_model.dart';
import 'package:candidate/data/models/exam_model.dart';
import 'package:candidate/data/models/question_model.dart';
import 'package:candidate/data/repositories/exams_repository.dart';
import 'package:candidate/features/result/cubit/result_cubit.dart';
import 'package:candidate/features/result/cubit/result_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExamsRepository extends Mock implements ExamsRepository {}

void main() {
  late MockExamsRepository mockExamsRepository;

  final sampleExam = ExamModel(
    id: 'exam_1',
    categoryId: 'cat_1',
    title: 'Highway Code Test',
    date: DateTime(2026, 11, 8),
    durationMin: 30,
    showScore: true,
    activeSlots: const {},
  );

  final sampleAttempt = AttemptModel(
    id: 'exam_1_user_1',
    examId: 'exam_1',
    candidateId: 'user_1',
    candidateName: 'John Candidate',
    status: 'finished',
    startedAt: DateTime(2026, 11, 8, 10, 0),
    endsAt: DateTime(2026, 11, 8, 10, 30),
    score: 2,
    durationSec: 420,
    currentIndex: 1,
    answers: const {'q_1': true, 'q_2': false},
  );

  const sampleQuestions = [
    QuestionModel(
      id: 'q_1',
      text: 'Stop on red',
      correctAnswer: true,
      order: 0,
    ),
    QuestionModel(
      id: 'q_2',
      text: 'Stop on green',
      correctAnswer: false,
      order: 1,
    ),
  ];

  setUp(() {
    mockExamsRepository = MockExamsRepository();
  });

  group('ResultCubit', () {
    test('initial state is correct', () {
      final cubit = ResultCubit(examsRepository: mockExamsRepository);
      expect(cubit.state, equals(const ResultState()));
    });

    blocTest<ResultCubit, ResultState>(
      'emits [loading, success] when loadResult succeeds with showScore true',
      build: () {
        when(() => mockExamsRepository.getExam('exam_1'))
            .thenAnswer((_) => Stream.value(sampleExam));
        when(() => mockExamsRepository.getAttempt('exam_1', 'user_1'))
            .thenAnswer((_) => Stream.value(sampleAttempt));
        when(() => mockExamsRepository.getQuestionsForExam('exam_1'))
            .thenAnswer((_) async => sampleQuestions);
        return ResultCubit(examsRepository: mockExamsRepository);
      },
      act: (cubit) => cubit.loadResult(examId: 'exam_1', uid: 'user_1'),
      expect: () => [
        const ResultState(status: ResultStatus.loading),
        const ResultState(
          status: ResultStatus.success,
          examTitle: 'Highway Code Test',
          showScore: true,
          candidateName: 'John Candidate',
          attemptStatus: 'finished',
          score: 2,
          totalQuestions: 2,
          durationSec: 420,
        ),
      ],
    );

    blocTest<ResultCubit, ResultState>(
      'emits [loading, success] when exam has showScore false',
      build: () {
        when(() => mockExamsRepository.getExam('exam_1'))
            .thenAnswer((_) => Stream.value(sampleExam.copyWith(showScore: false)));
        when(() => mockExamsRepository.getAttempt('exam_1', 'user_1'))
            .thenAnswer((_) => Stream.value(sampleAttempt));
        when(() => mockExamsRepository.getQuestionsForExam('exam_1'))
            .thenAnswer((_) async => sampleQuestions);
        return ResultCubit(examsRepository: mockExamsRepository);
      },
      act: (cubit) => cubit.loadResult(examId: 'exam_1', uid: 'user_1'),
      expect: () => [
        const ResultState(status: ResultStatus.loading),
        const ResultState(
          status: ResultStatus.success,
          examTitle: 'Highway Code Test',
          showScore: false,
          candidateName: 'John Candidate',
          attemptStatus: 'finished',
          score: 2,
          totalQuestions: 2,
          durationSec: 420,
        ),
      ],
    );

    blocTest<ResultCubit, ResultState>(
      'emits [loading, failure] when fetching exam throws',
      build: () {
        when(() => mockExamsRepository.getExam('exam_1'))
            .thenAnswer((_) => Stream.error(Exception('Network error')));
        return ResultCubit(examsRepository: mockExamsRepository);
      },
      act: (cubit) => cubit.loadResult(examId: 'exam_1', uid: 'user_1'),
      expect: () => [
        const ResultState(status: ResultStatus.loading),
        isA<ResultState>().having(
          (s) => s.status,
          'status',
          ResultStatus.failure,
        ),
      ],
    );
  });
}

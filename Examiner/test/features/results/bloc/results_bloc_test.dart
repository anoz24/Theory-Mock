import 'package:bloc_test/bloc_test.dart';
import 'package:examiner/data/models/attempt_model.dart';
import 'package:examiner/data/repositories/attempts_repository.dart';
import 'package:examiner/features/results/bloc/results_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAttemptsRepository extends Mock implements AttemptsRepository {}

void main() {
  late MockAttemptsRepository mockAttemptsRepository;

  final sampleAttempt = AttemptModel(
    id: 'exam_1_user_1',
    examId: 'exam_1',
    candidateId: 'user_1',
    candidateName: 'Jane Smith',
    status: 'finished',
    startedAt: DateTime(2026, 11, 8, 10, 0),
    endsAt: DateTime(2026, 11, 8, 10, 15),
    score: 8,
    durationSec: 900,
  );

  setUp(() {
    mockAttemptsRepository = MockAttemptsRepository();
  });

  group('ResultsBloc', () {
    test('initial state is correct', () {
      final bloc = ResultsBloc(attemptsRepository: mockAttemptsRepository);
      expect(bloc.state, equals(const ResultsState()));
    });

    blocTest<ResultsBloc, ResultsState>(
      'emits [loading, success] with finished attempts when stream succeeds',
      build: () {
        when(() => mockAttemptsRepository.getFinishedAttempts('exam_1'))
            .thenAnswer((_) => Stream.value([sampleAttempt]));
        return ResultsBloc(attemptsRepository: mockAttemptsRepository);
      },
      act: (bloc) => bloc.add(const ResultsSubscriptionRequested('exam_1')),
      expect: () => [
        const ResultsState(status: ResultsStatus.loading),
        ResultsState(
          status: ResultsStatus.success,
          attempts: [sampleAttempt],
        ),
      ],
    );

    blocTest<ResultsBloc, ResultsState>(
      'emits [loading, failure] when stream throws',
      build: () {
        when(() => mockAttemptsRepository.getFinishedAttempts('exam_1'))
            .thenAnswer((_) => Stream.error(Exception('Firestore error')));
        return ResultsBloc(attemptsRepository: mockAttemptsRepository);
      },
      act: (bloc) => bloc.add(const ResultsSubscriptionRequested('exam_1')),
      expect: () => [
        const ResultsState(status: ResultsStatus.loading),
        isA<ResultsState>()
            .having((s) => s.status, 'status', ResultsStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage',
                contains('Firestore error')),
      ],
    );
  });
}


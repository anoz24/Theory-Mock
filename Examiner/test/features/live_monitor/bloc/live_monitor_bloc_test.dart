import 'package:bloc_test/bloc_test.dart';
import 'package:examiner/data/models/attempt_model.dart';
import 'package:examiner/data/models/question_model.dart';
import 'package:examiner/data/repositories/attempts_repository.dart';
import 'package:examiner/data/repositories/exams_repository.dart';
import 'package:examiner/features/live_monitor/bloc/live_monitor_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAttemptsRepository extends Mock implements AttemptsRepository {}

class MockExamsRepository extends Mock implements ExamsRepository {}

void main() {
  late MockAttemptsRepository mockAttemptsRepository;
  late MockExamsRepository mockExamsRepository;

  const sampleQuestion = QuestionModel(
    id: 'q_1',
    text: 'Red means stop',
    correctAnswer: true,
    order: 0,
  );

  final sampleAttempt = AttemptModel(
    id: 'exam_1_user_1',
    examId: 'exam_1',
    candidateId: 'user_1',
    candidateName: 'John Doe',
    status: 'active',
    startedAt: DateTime(2026, 11, 8, 10, 0),
    endsAt: DateTime(2026, 11, 8, 10, 30),
    currentIndex: 0,
    answers: const {'q_1': true},
  );

  setUp(() {
    mockAttemptsRepository = MockAttemptsRepository();
    mockExamsRepository = MockExamsRepository();
  });

  group('LiveMonitorBloc', () {
    test('initial state is correct', () {
      final bloc = LiveMonitorBloc(
        attemptsRepository: mockAttemptsRepository,
        examsRepository: mockExamsRepository,
      );
      expect(bloc.state, equals(const LiveMonitorState()));
    });

    blocTest<LiveMonitorBloc, LiveMonitorState>(
      'emits loaded questions and stream of active attempts',
      build: () {
        when(() => mockExamsRepository.getQuestionsForExam('exam_1'))
            .thenAnswer((_) async => [sampleQuestion]);
        when(() => mockAttemptsRepository.getActiveAttempts('exam_1'))
            .thenAnswer((_) => Stream.value([sampleAttempt]));

        return LiveMonitorBloc(
          attemptsRepository: mockAttemptsRepository,
          examsRepository: mockExamsRepository,
        );
      },
      act: (bloc) => bloc.add(const LiveMonitorSubscriptionRequested('exam_1')),
      expect: () => [
        const LiveMonitorState(
          status: LiveMonitorStatus.loading,
          examId: 'exam_1',
        ),
        const LiveMonitorState(
          status: LiveMonitorStatus.loading,
          examId: 'exam_1',
          questions: [sampleQuestion],
        ),
        LiveMonitorState(
          status: LiveMonitorStatus.success,
          examId: 'exam_1',
          questions: const [sampleQuestion],
          activeAttempts: [sampleAttempt],
          selectedCandidateId: 'user_1',
        ),
      ],
    );

    blocTest<LiveMonitorBloc, LiveMonitorState>(
      'switches selectedCandidateId when LiveMonitorCandidateSelected is added',
      build: () => LiveMonitorBloc(
        attemptsRepository: mockAttemptsRepository,
        examsRepository: mockExamsRepository,
      ),
      seed: () => LiveMonitorState(
        status: LiveMonitorStatus.success,
        examId: 'exam_1',
        activeAttempts: [sampleAttempt],
        selectedCandidateId: 'user_1',
      ),
      act: (bloc) => bloc.add(const LiveMonitorCandidateSelected('user_2')),
      expect: () => [
        isA<LiveMonitorState>().having(
          (s) => s.selectedCandidateId,
          'selectedCandidateId',
          'user_2',
        ),
      ],
    );
  });
}


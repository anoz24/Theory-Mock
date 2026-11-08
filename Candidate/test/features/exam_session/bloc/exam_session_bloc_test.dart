import 'package:bloc_test/bloc_test.dart';
import 'package:candidate/data/models/attempt_model.dart';
import 'package:candidate/data/models/question_model.dart';
import 'package:candidate/data/repositories/exams_repository.dart';
import 'package:candidate/features/exam_session/bloc/exam_session_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExamsRepository extends Mock implements ExamsRepository {}

void main() {
  late MockExamsRepository mockExamsRepository;

  const sampleQuestion1 = QuestionModel(
    id: 'q_1',
    text: 'Red octagonal signs mean stop.',
    correctAnswer: true,
    order: 0,
  );

  const sampleQuestion2 = QuestionModel(
    id: 'q_2',
    text: 'A flashing yellow light means come to a complete stop.',
    correctAnswer: false,
    order: 1,
  );

  final sampleAttempt = AttemptModel(
    id: 'exam_1_uid_1',
    examId: 'exam_1',
    candidateId: 'uid_1',
    candidateName: 'Candidate One',
    status: 'active',
    startedAt: DateTime.now(),
    endsAt: DateTime.now().add(const Duration(minutes: 30)),
    currentIndex: 0,
    answers: const {},
  );

  setUp(() {
    mockExamsRepository = MockExamsRepository();
  });

  group('ExamSessionBloc', () {
    test('initial state has correct default values', () {
      final bloc = ExamSessionBloc(examsRepository: mockExamsRepository);
      expect(bloc.state, equals(const ExamSessionState()));
      expect(bloc.state.status, equals(ExamSessionStatus.initial));
    });

    blocTest<ExamSessionBloc, ExamSessionState>(
      'loads questions and starts session with initial attempt',
      build: () {
        when(() => mockExamsRepository.getQuestionsForExam('exam_1'))
            .thenAnswer((_) async => [sampleQuestion1, sampleQuestion2]);
        return ExamSessionBloc(examsRepository: mockExamsRepository);
      },
      act: (bloc) => bloc.add(ExamSessionStarted(
        examId: 'exam_1',
        uid: 'uid_1',
        initialAttempt: sampleAttempt,
      )),
      expect: () => [
        const ExamSessionState(
          status: ExamSessionStatus.loading,
          examId: 'exam_1',
          uid: 'uid_1',
        ),
        isA<ExamSessionState>()
            .having((s) => s.status, 'status', ExamSessionStatus.active)
            .having((s) => s.questions.length, 'questions.length', 2)
            .having((s) => s.currentIndex, 'currentIndex', 0),
      ],
    );

    blocTest<ExamSessionBloc, ExamSessionState>(
      'updates answer and writes progress to repository',
      build: () {
        when(() => mockExamsRepository.updateAttemptProgress(
              examId: any(named: 'examId'),
              uid: any(named: 'uid'),
              answers: any(named: 'answers'),
              currentIndex: any(named: 'currentIndex'),
            )).thenAnswer((_) async {});
        return ExamSessionBloc(examsRepository: mockExamsRepository);
      },
      seed: () => ExamSessionState(
        status: ExamSessionStatus.active,
        examId: 'exam_1',
        uid: 'uid_1',
        questions: const [sampleQuestion1, sampleQuestion2],
        currentIndex: 0,
      ),
      act: (bloc) => bloc.add(const ExamSessionAnswerSelected(
        questionId: 'q_1',
        answer: true,
      )),
      expect: () => [
        isA<ExamSessionState>().having(
          (s) => s.answers['q_1'],
          'answers[q_1]',
          true,
        ),
      ],
      verify: (_) {
        verify(() => mockExamsRepository.updateAttemptProgress(
              examId: 'exam_1',
              uid: 'uid_1',
              answers: {'q_1': true},
              currentIndex: 0,
            )).called(1);
      },
    );

    blocTest<ExamSessionBloc, ExamSessionState>(
      'navigates question palette index',
      build: () {
        when(() => mockExamsRepository.updateAttemptProgress(
              examId: any(named: 'examId'),
              uid: any(named: 'uid'),
              answers: any(named: 'answers'),
              currentIndex: any(named: 'currentIndex'),
            )).thenAnswer((_) async {});
        return ExamSessionBloc(examsRepository: mockExamsRepository);
      },
      seed: () => const ExamSessionState(
        status: ExamSessionStatus.active,
        examId: 'exam_1',
        uid: 'uid_1',
        questions: [sampleQuestion1, sampleQuestion2],
        currentIndex: 0,
      ),
      act: (bloc) => bloc.add(const ExamSessionIndexChanged(1)),
      expect: () => [
        isA<ExamSessionState>().having((s) => s.currentIndex, 'currentIndex', 1),
      ],
      verify: (_) {
        verify(() => mockExamsRepository.updateAttemptProgress(
              examId: 'exam_1',
              uid: 'uid_1',
              answers: const {},
              currentIndex: 1,
            )).called(1);
      },
    );

    blocTest<ExamSessionBloc, ExamSessionState>(
      'computes score and marks finished on ExamSessionFinishRequested',
      build: () {
        when(() => mockExamsRepository.finishAttempt(
              examId: any(named: 'examId'),
              uid: any(named: 'uid'),
              score: any(named: 'score'),
              durationSec: any(named: 'durationSec'),
            )).thenAnswer((_) async {});
        return ExamSessionBloc(examsRepository: mockExamsRepository);
      },
      seed: () => const ExamSessionState(
        status: ExamSessionStatus.active,
        examId: 'exam_1',
        uid: 'uid_1',
        questions: [sampleQuestion1, sampleQuestion2],
        answers: {
          'q_1': true, // correct (+1)
          'q_2': true, // incorrect, key is false (0)
        },
        remainingSeconds: 1500,
        totalDurationSeconds: 1800,
      ),
      act: (bloc) => bloc.add(const ExamSessionFinishRequested()),
      expect: () => [
        isA<ExamSessionState>().having(
          (s) => s.status,
          'status',
          ExamSessionStatus.submitting,
        ),
        isA<ExamSessionState>()
            .having((s) => s.status, 'status', ExamSessionStatus.finished)
            .having((s) => s.score, 'score', 1),
      ],
      verify: (_) {
        verify(() => mockExamsRepository.finishAttempt(
              examId: 'exam_1',
              uid: 'uid_1',
              score: 1,
              durationSec: 300,
            )).called(1);
      },
    );

    blocTest<ExamSessionBloc, ExamSessionState>(
      'marks quit with score 0 on ExamSessionQuitRequested',
      build: () {
        when(() => mockExamsRepository.quitAttempt(
              examId: any(named: 'examId'),
              uid: any(named: 'uid'),
              durationSec: any(named: 'durationSec'),
            )).thenAnswer((_) async {});
        return ExamSessionBloc(examsRepository: mockExamsRepository);
      },
      seed: () => const ExamSessionState(
        status: ExamSessionStatus.active,
        examId: 'exam_1',
        uid: 'uid_1',
        questions: [sampleQuestion1, sampleQuestion2],
        answers: {'q_1': true},
        remainingSeconds: 1200,
        totalDurationSeconds: 1800,
      ),
      act: (bloc) => bloc.add(const ExamSessionQuitRequested()),
      expect: () => [
        isA<ExamSessionState>().having(
          (s) => s.status,
          'status',
          ExamSessionStatus.submitting,
        ),
        isA<ExamSessionState>()
            .having((s) => s.status, 'status', ExamSessionStatus.quit)
            .having((s) => s.score, 'score', 0),
      ],
      verify: (_) {
        verify(() => mockExamsRepository.quitAttempt(
              examId: 'exam_1',
              uid: 'uid_1',
              durationSec: 600,
            )).called(1);
      },
    );

    blocTest<ExamSessionBloc, ExamSessionState>(
      'handles time expired and sets timeout status',
      build: () {
        when(() => mockExamsRepository.timeoutAttempt(
              examId: any(named: 'examId'),
              uid: any(named: 'uid'),
              score: any(named: 'score'),
              durationSec: any(named: 'durationSec'),
            )).thenAnswer((_) async {});
        return ExamSessionBloc(examsRepository: mockExamsRepository);
      },
      seed: () => const ExamSessionState(
        status: ExamSessionStatus.active,
        examId: 'exam_1',
        uid: 'uid_1',
        questions: [sampleQuestion1, sampleQuestion2],
        answers: {
          'q_1': true, // correct
          'q_2': false, // correct
        },
        remainingSeconds: 0,
        totalDurationSeconds: 1800,
      ),
      act: (bloc) => bloc.add(const ExamSessionTimeExpired()),
      expect: () => [
        isA<ExamSessionState>()
            .having((s) => s.status, 'status', ExamSessionStatus.submitting)
            .having((s) => s.remainingSeconds, 'remainingSeconds', 0),
        isA<ExamSessionState>()
            .having((s) => s.status, 'status', ExamSessionStatus.timeout)
            .having((s) => s.score, 'score', 2),
      ],
      verify: (_) {
        verify(() => mockExamsRepository.timeoutAttempt(
              examId: 'exam_1',
              uid: 'uid_1',
              score: 2,
              durationSec: 1800,
            )).called(1);
      },
    );
  });
}


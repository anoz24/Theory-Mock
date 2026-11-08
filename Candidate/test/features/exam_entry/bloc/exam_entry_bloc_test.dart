import 'package:bloc_test/bloc_test.dart';
import 'package:candidate/data/models/attempt_model.dart';
import 'package:candidate/data/models/exam_model.dart';
import 'package:candidate/data/repositories/exams_repository.dart';
import 'package:candidate/features/exam_entry/bloc/exam_entry_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExamsRepository extends Mock implements ExamsRepository {}

void main() {
  late MockExamsRepository mockExamsRepository;

  final sampleExam = ExamModel(
    id: 'exam_1',
    categoryId: 'cat_1',
    title: 'Driving Theory Exam 1',
    date: DateTime(2026, 11, 8, 14, 0),
    durationMin: 30,
  );

  final sampleAttempt = AttemptModel(
    id: 'exam_1_uid_1',
    examId: 'exam_1',
    candidateId: 'uid_1',
    candidateName: 'Candidate One',
    status: 'active',
    startedAt: DateTime(2026, 11, 8, 14, 0),
    endsAt: DateTime(2026, 11, 8, 14, 30),
  );

  setUp(() {
    mockExamsRepository = MockExamsRepository();
  });

  group('ExamEntryBloc', () {
    test('initial state has correct default values', () {
      final bloc = ExamEntryBloc(examsRepository: mockExamsRepository);
      expect(bloc.state, equals(const ExamEntryState()));
      expect(bloc.state.buttonState, equals(ExamButtonState.canStart));
    });

    blocTest<ExamEntryBloc, ExamEntryState>(
      'subscribes to exam and checks previous attempt',
      build: () {
        when(() => mockExamsRepository.hasCandidateAttempted('exam_1', 'uid_1'))
            .thenAnswer((_) async => false);
        when(() => mockExamsRepository.getExam('exam_1'))
            .thenAnswer((_) => Stream.value(sampleExam));
        return ExamEntryBloc(examsRepository: mockExamsRepository);
      },
      act: (bloc) => bloc.add(const ExamEntrySubscriptionRequested(
        examId: 'exam_1',
        uid: 'uid_1',
      )),
      expect: () => [
        const ExamEntryState(status: ExamEntryStatus.loading),
        ExamEntryState(
          status: ExamEntryStatus.success,
          exam: sampleExam,
          hasAttempted: false,
        ),
      ],
    );

    blocTest<ExamEntryBloc, ExamEntryState>(
      'marks hasAttempted true if already attempted',
      build: () {
        when(() => mockExamsRepository.hasCandidateAttempted('exam_1', 'uid_1'))
            .thenAnswer((_) async => true);
        when(() => mockExamsRepository.getExam('exam_1'))
            .thenAnswer((_) => Stream.value(sampleExam));
        return ExamEntryBloc(examsRepository: mockExamsRepository);
      },
      act: (bloc) => bloc.add(const ExamEntrySubscriptionRequested(
        examId: 'exam_1',
        uid: 'uid_1',
      )),
      expect: () => [
        const ExamEntryState(status: ExamEntryStatus.loading),
        const ExamEntryState(
          status: ExamEntryStatus.loading,
          hasAttempted: true,
        ),
        ExamEntryState(
          status: ExamEntryStatus.success,
          exam: sampleExam,
          hasAttempted: true,
        ),
      ],
      verify: (bloc) {
        expect(bloc.state.buttonState, equals(ExamButtonState.alreadyTaken));
      },
    );

    blocTest<ExamEntryBloc, ExamEntryState>(
      'admits candidate on successful startAttempt transaction',
      build: () {
        when(() => mockExamsRepository.startAttempt(
              examId: 'exam_1',
              uid: 'uid_1',
              candidateName: 'Candidate One',
            )).thenAnswer((_) async => Admitted(sampleAttempt));
        return ExamEntryBloc(examsRepository: mockExamsRepository);
      },
      act: (bloc) => bloc.add(const ExamEntryStartAttemptRequested(
        examId: 'exam_1',
        uid: 'uid_1',
        candidateName: 'Candidate One',
      )),
      expect: () => [
        const ExamEntryState(
          admissionStatus: ExamAdmissionStatus.starting,
        ),
        ExamEntryState(
          admissionStatus: ExamAdmissionStatus.admitted,
          admittedAttempt: sampleAttempt,
          hasAttempted: true,
        ),
      ],
    );

    blocTest<ExamEntryBloc, ExamEntryState>(
      'handles Full result from transaction (race condition)',
      build: () {
        when(() => mockExamsRepository.startAttempt(
              examId: 'exam_1',
              uid: 'uid_1',
              candidateName: 'Candidate One',
            )).thenAnswer((_) async => const Full());
        return ExamEntryBloc(examsRepository: mockExamsRepository);
      },
      act: (bloc) => bloc.add(const ExamEntryStartAttemptRequested(
        examId: 'exam_1',
        uid: 'uid_1',
        candidateName: 'Candidate One',
      )),
      expect: () => [
        const ExamEntryState(
          admissionStatus: ExamAdmissionStatus.starting,
        ),
        const ExamEntryState(
          admissionStatus: ExamAdmissionStatus.full,
        ),
      ],
    );

    blocTest<ExamEntryBloc, ExamEntryState>(
      'handles AlreadyTaken result from transaction',
      build: () {
        when(() => mockExamsRepository.startAttempt(
              examId: 'exam_1',
              uid: 'uid_1',
              candidateName: 'Candidate One',
            )).thenAnswer((_) async => const AlreadyTaken());
        return ExamEntryBloc(examsRepository: mockExamsRepository);
      },
      act: (bloc) => bloc.add(const ExamEntryStartAttemptRequested(
        examId: 'exam_1',
        uid: 'uid_1',
        candidateName: 'Candidate One',
      )),
      expect: () => [
        const ExamEntryState(
          admissionStatus: ExamAdmissionStatus.starting,
        ),
        const ExamEntryState(
          admissionStatus: ExamAdmissionStatus.alreadyTaken,
          hasAttempted: true,
        ),
      ],
    );
  });
}

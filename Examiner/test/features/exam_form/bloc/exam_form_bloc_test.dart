import 'package:bloc_test/bloc_test.dart';
import 'package:examiner/data/models/exam_model.dart';
import 'package:examiner/data/models/question_model.dart';
import 'package:examiner/data/repositories/exams_repository.dart';
import 'package:examiner/features/exam_form/bloc/exam_form_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExamsRepository extends Mock implements ExamsRepository {}

class FakeExamModel extends Fake implements ExamModel {}

void main() {
  late MockExamsRepository mockRepository;
  final fixedDate = DateTime(2026, 12, 1, 10, 0);

  setUpAll(() {
    registerFallbackValue(FakeExamModel());
    registerFallbackValue(<QuestionModel>[]);
  });

  setUp(() {
    mockRepository = MockExamsRepository();
  });

  group('ExamFormBloc', () {
    test('initial state has default question and values', () {
      final bloc = ExamFormBloc(
        examsRepository: mockRepository,
        categoryId: 'cat_1',
        initialDate: fixedDate,
      );

      expect(bloc.state.categoryId, equals('cat_1'));
      expect(bloc.state.date, equals(fixedDate));
      expect(bloc.state.durationMin, equals(30));
      expect(bloc.state.showScore, isTrue);
      expect(bloc.state.questions.length, equals(1));
      expect(bloc.state.status, equals(ExamFormStatus.initial));
    });

    blocTest<ExamFormBloc, ExamFormState>(
      'updates title when ExamFormTitleChanged is added',
      build: () => ExamFormBloc(
        examsRepository: mockRepository,
        categoryId: 'cat_1',
        initialDate: fixedDate,
      ),
      act: (bloc) => bloc.add(const ExamFormTitleChanged('Mock Exam 1')),
      expect: () => [
        isA<ExamFormState>().having((s) => s.title, 'title', 'Mock Exam 1'),
      ],
    );

    blocTest<ExamFormBloc, ExamFormState>(
      'adds and removes questions properly',
      build: () => ExamFormBloc(
        examsRepository: mockRepository,
        categoryId: 'cat_1',
        initialDate: fixedDate,
      ),
      act: (bloc) {
        bloc.add(const ExamFormQuestionAdded());
        bloc.add(const ExamFormQuestionRemoved(0));
      },
      expect: () => [
        isA<ExamFormState>()
            .having((s) => s.questions.length, 'questions.length', 2),
        isA<ExamFormState>()
            .having((s) => s.questions.length, 'questions.length', 1),
      ],
    );

    blocTest<ExamFormBloc, ExamFormState>(
      'updates question text and answer',
      build: () => ExamFormBloc(
        examsRepository: mockRepository,
        categoryId: 'cat_1',
        initialDate: fixedDate,
      ),
      act: (bloc) {
        bloc.add(const ExamFormQuestionTextChanged(
          index: 0,
          text: 'Red lights mean stop.',
        ));
        bloc.add(const ExamFormQuestionAnswerChanged(
          index: 0,
          correctAnswer: false,
        ));
      },
      expect: () => [
        isA<ExamFormState>().having(
          (s) => s.questions[0].text,
          'questions[0].text',
          'Red lights mean stop.',
        ),
        isA<ExamFormState>().having(
          (s) => s.questions[0].correctAnswer,
          'questions[0].correctAnswer',
          false,
        ),
      ],
    );

    blocTest<ExamFormBloc, ExamFormState>(
      'fails submission when title is empty',
      build: () => ExamFormBloc(
        examsRepository: mockRepository,
        categoryId: 'cat_1',
        initialDate: fixedDate,
      ),
      act: (bloc) => bloc.add(const ExamFormSubmitted()),
      expect: () => [
        isA<ExamFormState>()
            .having((s) => s.status, 'status', ExamFormStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage',
                'Exam title is required'),
      ],
    );

    blocTest<ExamFormBloc, ExamFormState>(
      'fails submission when question text is empty',
      build: () => ExamFormBloc(
        examsRepository: mockRepository,
        categoryId: 'cat_1',
        initialDate: fixedDate,
      ),
      seed: () => ExamFormState(
        categoryId: 'cat_1',
        title: 'Valid Title',
        date: fixedDate,
        questions: const [
          QuestionDraft(id: '1', text: '   ', correctAnswer: true),
        ],
      ),
      act: (bloc) => bloc.add(const ExamFormSubmitted()),
      expect: () => [
        isA<ExamFormState>()
            .having((s) => s.status, 'status', ExamFormStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage',
                'Question 1 cannot be empty'),
      ],
    );

    blocTest<ExamFormBloc, ExamFormState>(
      'submits successfully when form is valid',
      build: () {
        when(() => mockRepository.createExam(
              exam: any(named: 'exam'),
              questions: any(named: 'questions'),
            )).thenAnswer((_) async => 'exam_new_id');
        return ExamFormBloc(
          examsRepository: mockRepository,
          categoryId: 'cat_1',
          initialDate: fixedDate,
        );
      },
      seed: () => ExamFormState(
        categoryId: 'cat_1',
        title: 'Road Signs Final',
        date: fixedDate,
        durationMin: 45,
        showScore: true,
        questions: const [
          QuestionDraft(
            id: '1',
            text: 'Stop signs are octagonal.',
            correctAnswer: true,
          ),
        ],
      ),
      act: (bloc) => bloc.add(const ExamFormSubmitted()),
      expect: () => [
        isA<ExamFormState>()
            .having((s) => s.status, 'status', ExamFormStatus.submitting),
        isA<ExamFormState>()
            .having((s) => s.status, 'status', ExamFormStatus.success),
      ],
      verify: (_) {
        verify(() => mockRepository.createExam(
              exam: any(named: 'exam'),
              questions: any(named: 'questions'),
            )).called(1);
      },
    );

    blocTest<ExamFormBloc, ExamFormState>(
      'emits failure when repository throws during submission',
      build: () {
        when(() => mockRepository.createExam(
              exam: any(named: 'exam'),
              questions: any(named: 'questions'),
            )).thenThrow(Exception('Firestore write failed'));
        return ExamFormBloc(
          examsRepository: mockRepository,
          categoryId: 'cat_1',
          initialDate: fixedDate,
        );
      },
      seed: () => ExamFormState(
        categoryId: 'cat_1',
        title: 'Road Signs Final',
        date: fixedDate,
        questions: const [
          QuestionDraft(
            id: '1',
            text: 'Stop signs are octagonal.',
            correctAnswer: true,
          ),
        ],
      ),
      act: (bloc) => bloc.add(const ExamFormSubmitted()),
      expect: () => [
        isA<ExamFormState>()
            .having((s) => s.status, 'status', ExamFormStatus.submitting),
        isA<ExamFormState>()
            .having((s) => s.status, 'status', ExamFormStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage',
                contains('Firestore write failed')),
      ],
    );
  });
}


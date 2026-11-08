import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/exam_model.dart';
import '../../../data/models/question_model.dart';
import '../../../data/repositories/exams_repository.dart';

part 'exam_form_event.dart';
part 'exam_form_state.dart';

class ExamFormBloc extends Bloc<ExamFormEvent, ExamFormState> {
  final ExamsRepository examsRepository;

  ExamFormBloc({
    required this.examsRepository,
    required String categoryId,
    DateTime? initialDate,
  }) : super(ExamFormState(
          categoryId: categoryId,
          date: initialDate ?? DateTime.now(),
        )) {
    on<ExamFormTitleChanged>(_onTitleChanged);
    on<ExamFormDateChanged>(_onDateChanged);
    on<ExamFormDurationChanged>(_onDurationChanged);
    on<ExamFormShowScoreToggled>(_onShowScoreToggled);
    on<ExamFormQuestionAdded>(_onQuestionAdded);
    on<ExamFormQuestionRemoved>(_onQuestionRemoved);
    on<ExamFormQuestionTextChanged>(_onQuestionTextChanged);
    on<ExamFormQuestionAnswerChanged>(_onQuestionAnswerChanged);
    on<ExamFormSubmitted>(_onSubmitted);
  }

  void _onTitleChanged(
    ExamFormTitleChanged event,
    Emitter<ExamFormState> emit,
  ) {
    emit(state.copyWith(
      title: event.title,
      status: ExamFormStatus.initial,
      errorMessage: null,
    ));
  }

  void _onDateChanged(
    ExamFormDateChanged event,
    Emitter<ExamFormState> emit,
  ) {
    emit(state.copyWith(
      date: event.date,
      status: ExamFormStatus.initial,
      errorMessage: null,
    ));
  }

  void _onDurationChanged(
    ExamFormDurationChanged event,
    Emitter<ExamFormState> emit,
  ) {
    emit(state.copyWith(
      durationMin: event.durationMin,
      status: ExamFormStatus.initial,
      errorMessage: null,
    ));
  }

  void _onShowScoreToggled(
    ExamFormShowScoreToggled event,
    Emitter<ExamFormState> emit,
  ) {
    emit(state.copyWith(
      showScore: event.showScore,
      status: ExamFormStatus.initial,
      errorMessage: null,
    ));
  }

  void _onQuestionAdded(
    ExamFormQuestionAdded event,
    Emitter<ExamFormState> emit,
  ) {
    final updated = List<QuestionDraft>.from(state.questions)
      ..add(QuestionDraft(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: '',
        correctAnswer: true,
      ));
    emit(state.copyWith(
      questions: updated,
      status: ExamFormStatus.initial,
      errorMessage: null,
    ));
  }

  void _onQuestionRemoved(
    ExamFormQuestionRemoved event,
    Emitter<ExamFormState> emit,
  ) {
    if (event.index < 0 || event.index >= state.questions.length) return;
    final updated = List<QuestionDraft>.from(state.questions)
      ..removeAt(event.index);
    emit(state.copyWith(
      questions: updated,
      status: ExamFormStatus.initial,
      errorMessage: null,
    ));
  }

  void _onQuestionTextChanged(
    ExamFormQuestionTextChanged event,
    Emitter<ExamFormState> emit,
  ) {
    if (event.index < 0 || event.index >= state.questions.length) return;
    final updated = List<QuestionDraft>.from(state.questions);
    updated[event.index] = updated[event.index].copyWith(text: event.text);
    emit(state.copyWith(
      questions: updated,
      status: ExamFormStatus.initial,
      errorMessage: null,
    ));
  }

  void _onQuestionAnswerChanged(
    ExamFormQuestionAnswerChanged event,
    Emitter<ExamFormState> emit,
  ) {
    if (event.index < 0 || event.index >= state.questions.length) return;
    final updated = List<QuestionDraft>.from(state.questions);
    updated[event.index] =
        updated[event.index].copyWith(correctAnswer: event.correctAnswer);
    emit(state.copyWith(
      questions: updated,
      status: ExamFormStatus.initial,
      errorMessage: null,
    ));
  }

  Future<void> _onSubmitted(
    ExamFormSubmitted event,
    Emitter<ExamFormState> emit,
  ) async {
    final trimmedTitle = state.title.trim();
    if (trimmedTitle.isEmpty) {
      emit(state.copyWith(
        status: ExamFormStatus.failure,
        errorMessage: 'Exam title is required',
      ));
      return;
    }

    if (state.durationMin <= 0) {
      emit(state.copyWith(
        status: ExamFormStatus.failure,
        errorMessage: 'Duration must be greater than 0 minutes',
      ));
      return;
    }

    if (state.questions.isEmpty) {
      emit(state.copyWith(
        status: ExamFormStatus.failure,
        errorMessage: 'At least one question is required',
      ));
      return;
    }

    for (var i = 0; i < state.questions.length; i++) {
      if (state.questions[i].text.trim().isEmpty) {
        emit(state.copyWith(
          status: ExamFormStatus.failure,
          errorMessage: 'Question ${i + 1} cannot be empty',
        ));
        return;
      }
    }

    emit(state.copyWith(status: ExamFormStatus.submitting));

    try {
      final exam = ExamModel(
        id: '',
        categoryId: state.categoryId,
        title: trimmedTitle,
        date: state.date,
        durationMin: state.durationMin,
        showScore: state.showScore,
      );

      final questions = state.questions.asMap().entries.map((entry) {
        return QuestionModel(
          id: '',
          text: entry.value.text.trim(),
          correctAnswer: entry.value.correctAnswer,
          order: entry.key,
        );
      }).toList();

      await examsRepository.createExam(
        exam: exam,
        questions: questions,
      );

      emit(state.copyWith(status: ExamFormStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: ExamFormStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}


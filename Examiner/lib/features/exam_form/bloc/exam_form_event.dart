part of 'exam_form_bloc.dart';

abstract class ExamFormEvent extends Equatable {
  const ExamFormEvent();

  @override
  List<Object?> get props => [];
}

class ExamFormTitleChanged extends ExamFormEvent {
  final String title;

  const ExamFormTitleChanged(this.title);

  @override
  List<Object?> get props => [title];
}

class ExamFormDateChanged extends ExamFormEvent {
  final DateTime date;

  const ExamFormDateChanged(this.date);

  @override
  List<Object?> get props => [date];
}

class ExamFormDurationChanged extends ExamFormEvent {
  final int durationMin;

  const ExamFormDurationChanged(this.durationMin);

  @override
  List<Object?> get props => [durationMin];
}

class ExamFormShowScoreToggled extends ExamFormEvent {
  final bool showScore;

  const ExamFormShowScoreToggled(this.showScore);

  @override
  List<Object?> get props => [showScore];
}

class ExamFormQuestionAdded extends ExamFormEvent {
  const ExamFormQuestionAdded();
}

class ExamFormQuestionRemoved extends ExamFormEvent {
  final int index;

  const ExamFormQuestionRemoved(this.index);

  @override
  List<Object?> get props => [index];
}

class ExamFormQuestionTextChanged extends ExamFormEvent {
  final int index;
  final String text;

  const ExamFormQuestionTextChanged({
    required this.index,
    required this.text,
  });

  @override
  List<Object?> get props => [index, text];
}

class ExamFormQuestionAnswerChanged extends ExamFormEvent {
  final int index;
  final bool correctAnswer;

  const ExamFormQuestionAnswerChanged({
    required this.index,
    required this.correctAnswer,
  });

  @override
  List<Object?> get props => [index, correctAnswer];
}

class ExamFormSubmitted extends ExamFormEvent {
  const ExamFormSubmitted();
}


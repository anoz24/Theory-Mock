part of 'exam_form_bloc.dart';

class QuestionDraft extends Equatable {
  final String id;
  final String text;
  final bool correctAnswer;

  const QuestionDraft({
    required this.id,
    this.text = '',
    this.correctAnswer = true,
  });

  QuestionDraft copyWith({
    String? id,
    String? text,
    bool? correctAnswer,
  }) {
    return QuestionDraft(
      id: id ?? this.id,
      text: text ?? this.text,
      correctAnswer: correctAnswer ?? this.correctAnswer,
    );
  }

  @override
  List<Object?> get props => [id, text, correctAnswer];
}

enum ExamFormStatus { initial, submitting, success, failure }

class ExamFormState extends Equatable {
  final ExamFormStatus status;
  final String categoryId;
  final String title;
  final DateTime date;
  final int durationMin;
  final bool showScore;
  final List<QuestionDraft> questions;
  final String? errorMessage;

  const ExamFormState({
    this.status = ExamFormStatus.initial,
    required this.categoryId,
    this.title = '',
    required this.date,
    this.durationMin = 30,
    this.showScore = true,
    this.questions = const [
      QuestionDraft(id: '1', text: '', correctAnswer: true),
    ],
    this.errorMessage,
  });

  ExamFormState copyWith({
    ExamFormStatus? status,
    String? categoryId,
    String? title,
    DateTime? date,
    int? durationMin,
    bool? showScore,
    List<QuestionDraft>? questions,
    String? errorMessage,
  }) {
    return ExamFormState(
      status: status ?? this.status,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      date: date ?? this.date,
      durationMin: durationMin ?? this.durationMin,
      showScore: showScore ?? this.showScore,
      questions: questions ?? this.questions,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        categoryId,
        title,
        date,
        durationMin,
        showScore,
        questions,
        errorMessage,
      ];
}


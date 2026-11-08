part of 'exam_session_bloc.dart';

enum ExamSessionStatus {
  initial,
  loading,
  active,
  submitting,
  finished,
  timeout,
  quit,
  failure,
}

class ExamSessionState extends Equatable {
  final ExamSessionStatus status;
  final String examId;
  final String uid;
  final List<QuestionModel> questions;
  final int currentIndex;
  final Map<String, bool> answers;
  final int remainingSeconds;
  final int totalDurationSeconds;
  final AttemptModel? attempt;
  final int score;
  final String? errorMessage;

  const ExamSessionState({
    this.status = ExamSessionStatus.initial,
    this.examId = '',
    this.uid = '',
    this.questions = const [],
    this.currentIndex = 0,
    this.answers = const {},
    this.remainingSeconds = 0,
    this.totalDurationSeconds = 0,
    this.attempt,
    this.score = 0,
    this.errorMessage,
  });

  QuestionModel? get currentQuestion {
    if (questions.isEmpty ||
        currentIndex < 0 ||
        currentIndex >= questions.length) {
      return null;
    }
    return questions[currentIndex];
  }

  bool get isFirstQuestion => currentIndex <= 0;
  bool get isLastQuestion =>
      questions.isNotEmpty && currentIndex >= questions.length - 1;

  ExamSessionState copyWith({
    ExamSessionStatus? status,
    String? examId,
    String? uid,
    List<QuestionModel>? questions,
    int? currentIndex,
    Map<String, bool>? answers,
    int? remainingSeconds,
    int? totalDurationSeconds,
    AttemptModel? attempt,
    int? score,
    String? errorMessage,
  }) {
    return ExamSessionState(
      status: status ?? this.status,
      examId: examId ?? this.examId,
      uid: uid ?? this.uid,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      attempt: attempt ?? this.attempt,
      score: score ?? this.score,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        examId,
        uid,
        questions,
        currentIndex,
        answers,
        remainingSeconds,
        totalDurationSeconds,
        attempt,
        score,
        errorMessage,
      ];
}


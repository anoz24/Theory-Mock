part of 'exam_session_bloc.dart';

abstract class ExamSessionEvent extends Equatable {
  const ExamSessionEvent();

  @override
  List<Object?> get props => [];
}

class ExamSessionStarted extends ExamSessionEvent {
  final String examId;
  final String uid;
  final AttemptModel? initialAttempt;

  const ExamSessionStarted({
    required this.examId,
    required this.uid,
    this.initialAttempt,
  });

  @override
  List<Object?> get props => [examId, uid, initialAttempt];
}

class ExamSessionAnswerSelected extends ExamSessionEvent {
  final String questionId;
  final bool answer;

  const ExamSessionAnswerSelected({
    required this.questionId,
    required this.answer,
  });

  @override
  List<Object?> get props => [questionId, answer];
}

class ExamSessionIndexChanged extends ExamSessionEvent {
  final int index;

  const ExamSessionIndexChanged(this.index);

  @override
  List<Object?> get props => [index];
}

class ExamSessionTimerTicked extends ExamSessionEvent {
  final int remainingSeconds;

  const ExamSessionTimerTicked(this.remainingSeconds);

  @override
  List<Object?> get props => [remainingSeconds];
}

class ExamSessionTimeExpired extends ExamSessionEvent {
  const ExamSessionTimeExpired();
}

class ExamSessionFinishRequested extends ExamSessionEvent {
  const ExamSessionFinishRequested();
}

class ExamSessionQuitRequested extends ExamSessionEvent {
  const ExamSessionQuitRequested();
}


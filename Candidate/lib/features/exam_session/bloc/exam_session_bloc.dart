import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/attempt_model.dart';
import '../../../data/models/question_model.dart';
import '../../../data/repositories/exams_repository.dart';

part 'exam_session_event.dart';
part 'exam_session_state.dart';

class ExamSessionBloc extends Bloc<ExamSessionEvent, ExamSessionState> {
  final ExamsRepository examsRepository;
  StreamSubscription<int>? _timerSubscription;

  ExamSessionBloc({required this.examsRepository})
      : super(const ExamSessionState()) {
    on<ExamSessionStarted>(_onStarted);
    on<ExamSessionAnswerSelected>(_onAnswerSelected);
    on<ExamSessionIndexChanged>(_onIndexChanged);
    on<ExamSessionTimerTicked>(_onTimerTicked);
    on<ExamSessionTimeExpired>(_onTimeExpired);
    on<ExamSessionFinishRequested>(_onFinishRequested);
    on<ExamSessionQuitRequested>(_onQuitRequested);
  }

  Future<void> _onStarted(
    ExamSessionStarted event,
    Emitter<ExamSessionState> emit,
  ) async {
    emit(state.copyWith(
      status: ExamSessionStatus.loading,
      examId: event.examId,
      uid: event.uid,
    ));

    try {
      final questions =
          await examsRepository.getQuestionsForExam(event.examId);

      AttemptModel? attempt = event.initialAttempt;
      attempt ??= await examsRepository.getAttempt(event.examId, event.uid).first;

      if (attempt == null) {
        emit(state.copyWith(
          status: ExamSessionStatus.failure,
          errorMessage: 'Attempt record not found',
        ));
        return;
      }

      if (attempt.status != 'active') {
        emit(state.copyWith(
          status: _mapStatus(attempt.status),
          attempt: attempt,
          questions: questions,
          score: attempt.score,
        ));
        return;
      }

      final totalSeconds =
          attempt.endsAt.difference(attempt.startedAt).inSeconds;
      final remaining = attempt.endsAt.difference(DateTime.now()).inSeconds;

      if (remaining <= 0) {
        add(const ExamSessionTimeExpired());
        return;
      }

      emit(state.copyWith(
        status: ExamSessionStatus.active,
        questions: questions,
        attempt: attempt,
        currentIndex: attempt.currentIndex.clamp(
          0,
          questions.isNotEmpty ? questions.length - 1 : 0,
        ),
        answers: Map<String, bool>.from(attempt.answers),
        remainingSeconds: remaining,
        totalDurationSeconds: totalSeconds > 0 ? totalSeconds : remaining,
      ));

      await _timerSubscription?.cancel();
      _timerSubscription = Stream.periodic(
        const Duration(seconds: 1),
        (x) => remaining - x - 1,
      ).listen((rem) {
        if (rem > 0) {
          add(ExamSessionTimerTicked(rem));
        } else {
          add(const ExamSessionTimeExpired());
        }
      });
    } catch (e) {
      emit(state.copyWith(
        status: ExamSessionStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onTimerTicked(
    ExamSessionTimerTicked event,
    Emitter<ExamSessionState> emit,
  ) {
    if (state.status == ExamSessionStatus.active) {
      emit(state.copyWith(remainingSeconds: event.remainingSeconds));
    }
  }

  Future<void> _onAnswerSelected(
    ExamSessionAnswerSelected event,
    Emitter<ExamSessionState> emit,
  ) async {
    final updatedAnswers = Map<String, bool>.from(state.answers)
      ..[event.questionId] = event.answer;

    emit(state.copyWith(answers: updatedAnswers));

    try {
      await examsRepository.updateAttemptProgress(
        examId: state.examId,
        uid: state.uid,
        answers: updatedAnswers,
        currentIndex: state.currentIndex,
      );
    } catch (_) {
      // Background write failure shouldn't freeze the candidate's screen
    }
  }

  Future<void> _onIndexChanged(
    ExamSessionIndexChanged event,
    Emitter<ExamSessionState> emit,
  ) async {
    if (event.index < 0 || event.index >= state.questions.length) return;
    emit(state.copyWith(currentIndex: event.index));

    try {
      await examsRepository.updateAttemptProgress(
        examId: state.examId,
        uid: state.uid,
        answers: state.answers,
        currentIndex: event.index,
      );
    } catch (_) {}
  }

  Future<void> _onFinishRequested(
    ExamSessionFinishRequested event,
    Emitter<ExamSessionState> emit,
  ) async {
    await _timerSubscription?.cancel();
    emit(state.copyWith(status: ExamSessionStatus.submitting));

    final score = _computeScore();
    final durationSec = (state.totalDurationSeconds - state.remainingSeconds)
        .clamp(0, state.totalDurationSeconds);

    try {
      await examsRepository.finishAttempt(
        examId: state.examId,
        uid: state.uid,
        score: score,
        durationSec: durationSec,
      );

      emit(state.copyWith(
        status: ExamSessionStatus.finished,
        score: score,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExamSessionStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onQuitRequested(
    ExamSessionQuitRequested event,
    Emitter<ExamSessionState> emit,
  ) async {
    await _timerSubscription?.cancel();
    emit(state.copyWith(status: ExamSessionStatus.submitting));

    final durationSec = (state.totalDurationSeconds - state.remainingSeconds)
        .clamp(0, state.totalDurationSeconds);

    try {
      await examsRepository.quitAttempt(
        examId: state.examId,
        uid: state.uid,
        durationSec: durationSec,
      );

      emit(state.copyWith(
        status: ExamSessionStatus.quit,
        score: 0,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExamSessionStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onTimeExpired(
    ExamSessionTimeExpired event,
    Emitter<ExamSessionState> emit,
  ) async {
    await _timerSubscription?.cancel();
    emit(state.copyWith(
      status: ExamSessionStatus.submitting,
      remainingSeconds: 0,
    ));

    final score = _computeScore();
    final durationSec = state.totalDurationSeconds;

    try {
      await examsRepository.timeoutAttempt(
        examId: state.examId,
        uid: state.uid,
        score: score,
        durationSec: durationSec,
      );

      emit(state.copyWith(
        status: ExamSessionStatus.timeout,
        score: score,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExamSessionStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  int _computeScore() {
    var score = 0;
    for (final q in state.questions) {
      if (state.answers.containsKey(q.id) &&
          state.answers[q.id] == q.correctAnswer) {
        score++;
      }
    }
    return score;
  }

  ExamSessionStatus _mapStatus(String status) {
    switch (status) {
      case 'finished':
        return ExamSessionStatus.finished;
      case 'timeout':
        return ExamSessionStatus.timeout;
      case 'quit':
        return ExamSessionStatus.quit;
      default:
        return ExamSessionStatus.active;
    }
  }

  @override
  Future<void> close() {
    _timerSubscription?.cancel();
    return super.close();
  }
}

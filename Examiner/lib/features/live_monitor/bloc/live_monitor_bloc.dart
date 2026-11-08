import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/attempt_model.dart';
import '../../../data/models/question_model.dart';
import '../../../data/repositories/attempts_repository.dart';
import '../../../data/repositories/exams_repository.dart';

part 'live_monitor_event.dart';
part 'live_monitor_state.dart';

class LiveMonitorBloc extends Bloc<LiveMonitorEvent, LiveMonitorState> {
  final AttemptsRepository attemptsRepository;
  final ExamsRepository examsRepository;

  LiveMonitorBloc({
    required this.attemptsRepository,
    required this.examsRepository,
  }) : super(const LiveMonitorState()) {
    on<LiveMonitorSubscriptionRequested>(_onSubscriptionRequested);
    on<LiveMonitorCandidateSelected>(_onCandidateSelected);
  }

  Future<void> _onSubscriptionRequested(
    LiveMonitorSubscriptionRequested event,
    Emitter<LiveMonitorState> emit,
  ) async {
    emit(state.copyWith(
      status: LiveMonitorStatus.loading,
      examId: event.examId,
    ));

    try {
      final questions =
          await examsRepository.getQuestionsForExam(event.examId);
      emit(state.copyWith(questions: questions));

      await emit.forEach<List<AttemptModel>>(
        attemptsRepository.getActiveAttempts(event.examId),
        onData: (attempts) {
          String? nextSelectedId = state.selectedCandidateId;
          final candidateExists = attempts.any(
            (a) => a.candidateId == nextSelectedId,
          );
          if (!candidateExists) {
            nextSelectedId =
                attempts.isNotEmpty ? attempts.first.candidateId : null;
          }

          return state.copyWith(
            status: LiveMonitorStatus.success,
            activeAttempts: attempts,
            selectedCandidateId: nextSelectedId,
          );
        },
        onError: (error, _) => state.copyWith(
          status: LiveMonitorStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    } catch (e) {
      emit(state.copyWith(
        status: LiveMonitorStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onCandidateSelected(
    LiveMonitorCandidateSelected event,
    Emitter<LiveMonitorState> emit,
  ) {
    emit(state.copyWith(selectedCandidateId: event.candidateId));
  }
}


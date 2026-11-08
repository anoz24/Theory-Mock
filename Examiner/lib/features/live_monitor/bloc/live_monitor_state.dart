part of 'live_monitor_bloc.dart';

enum LiveMonitorStatus { initial, loading, success, failure }

class LiveMonitorState extends Equatable {
  final LiveMonitorStatus status;
  final String examId;
  final List<QuestionModel> questions;
  final List<AttemptModel> activeAttempts;
  final String? selectedCandidateId;
  final String? errorMessage;

  const LiveMonitorState({
    this.status = LiveMonitorStatus.initial,
    this.examId = '',
    this.questions = const [],
    this.activeAttempts = const [],
    this.selectedCandidateId,
    this.errorMessage,
  });

  AttemptModel? get selectedAttempt {
    if (activeAttempts.isEmpty) return null;
    if (selectedCandidateId == null) return activeAttempts.first;
    for (final attempt in activeAttempts) {
      if (attempt.candidateId == selectedCandidateId) {
        return attempt;
      }
    }
    return activeAttempts.first;
  }

  LiveMonitorState copyWith({
    LiveMonitorStatus? status,
    String? examId,
    List<QuestionModel>? questions,
    List<AttemptModel>? activeAttempts,
    String? selectedCandidateId,
    String? errorMessage,
  }) {
    return LiveMonitorState(
      status: status ?? this.status,
      examId: examId ?? this.examId,
      questions: questions ?? this.questions,
      activeAttempts: activeAttempts ?? this.activeAttempts,
      selectedCandidateId: selectedCandidateId ?? this.selectedCandidateId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        examId,
        questions,
        activeAttempts,
        selectedCandidateId,
        errorMessage,
      ];
}


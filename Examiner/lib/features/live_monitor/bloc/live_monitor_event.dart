part of 'live_monitor_bloc.dart';

abstract class LiveMonitorEvent extends Equatable {
  const LiveMonitorEvent();

  @override
  List<Object?> get props => [];
}

class LiveMonitorSubscriptionRequested extends LiveMonitorEvent {
  final String examId;

  const LiveMonitorSubscriptionRequested(this.examId);

  @override
  List<Object?> get props => [examId];
}

class LiveMonitorCandidateSelected extends LiveMonitorEvent {
  final String candidateId;

  const LiveMonitorCandidateSelected(this.candidateId);

  @override
  List<Object?> get props => [candidateId];
}


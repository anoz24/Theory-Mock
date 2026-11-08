part of 'results_bloc.dart';

abstract class ResultsEvent extends Equatable {
  const ResultsEvent();

  @override
  List<Object?> get props => [];
}

class ResultsSubscriptionRequested extends ResultsEvent {
  final String examId;

  const ResultsSubscriptionRequested(this.examId);

  @override
  List<Object?> get props => [examId];
}


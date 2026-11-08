part of 'results_bloc.dart';

enum ResultsStatus { initial, loading, success, failure }

class ResultsState extends Equatable {
  final ResultsStatus status;
  final List<AttemptModel> attempts;
  final String? errorMessage;

  const ResultsState({
    this.status = ResultsStatus.initial,
    this.attempts = const [],
    this.errorMessage,
  });

  ResultsState copyWith({
    ResultsStatus? status,
    List<AttemptModel>? attempts,
    String? errorMessage,
  }) {
    return ResultsState(
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, attempts, errorMessage];
}


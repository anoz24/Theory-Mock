import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/attempt_model.dart';
import '../../../data/repositories/attempts_repository.dart';

part 'results_event.dart';
part 'results_state.dart';

class ResultsBloc extends Bloc<ResultsEvent, ResultsState> {
  final AttemptsRepository attemptsRepository;

  ResultsBloc({required this.attemptsRepository})
      : super(const ResultsState()) {
    on<ResultsSubscriptionRequested>(_onSubscriptionRequested);
  }

  Future<void> _onSubscriptionRequested(
    ResultsSubscriptionRequested event,
    Emitter<ResultsState> emit,
  ) async {
    emit(state.copyWith(status: ResultsStatus.loading));
    await emit.forEach<List<AttemptModel>>(
      attemptsRepository.getFinishedAttempts(event.examId),
      onData: (attempts) => state.copyWith(
        status: ResultsStatus.success,
        attempts: attempts,
      ),
      onError: (error, _) => state.copyWith(
        status: ResultsStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }
}


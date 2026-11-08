import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/exam_model.dart';
import '../../../data/repositories/exams_repository.dart';

part 'exams_event.dart';
part 'exams_state.dart';

class ExamsBloc extends Bloc<ExamsEvent, ExamsState> {
  final ExamsRepository examsRepository;

  ExamsBloc({required this.examsRepository}) : super(const ExamsState()) {
    on<ExamsSubscriptionRequested>(_onSubscriptionRequested);
    on<ExamDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onSubscriptionRequested(
    ExamsSubscriptionRequested event,
    Emitter<ExamsState> emit,
  ) async {
    emit(state.copyWith(status: ExamsStatus.loading));
    await emit.forEach<List<ExamModel>>(
      examsRepository.getExamsForCategory(event.categoryId),
      onData: (exams) => state.copyWith(
        status: ExamsStatus.success,
        exams: exams,
      ),
      onError: (error, _) => state.copyWith(
        status: ExamsStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  Future<void> _onDeleteRequested(
    ExamDeleteRequested event,
    Emitter<ExamsState> emit,
  ) async {
    try {
      await examsRepository.deleteExam(event.examId);
    } catch (e) {
      emit(state.copyWith(actionErrorMessage: e.toString()));
    }
  }
}


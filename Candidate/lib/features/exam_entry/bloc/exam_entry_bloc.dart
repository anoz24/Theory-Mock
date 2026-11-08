import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/attempt_model.dart';
import '../../../data/models/exam_model.dart';
import '../../../data/repositories/exams_repository.dart';

part 'exam_entry_event.dart';
part 'exam_entry_state.dart';

class ExamEntryBloc extends Bloc<ExamEntryEvent, ExamEntryState> {
  final ExamsRepository examsRepository;

  ExamEntryBloc({required this.examsRepository})
      : super(const ExamEntryState()) {
    on<ExamEntrySubscriptionRequested>(_onSubscriptionRequested);
    on<ExamEntryStartAttemptRequested>(_onStartAttemptRequested);
  }

  Future<void> _onSubscriptionRequested(
    ExamEntrySubscriptionRequested event,
    Emitter<ExamEntryState> emit,
  ) async {
    emit(state.copyWith(status: ExamEntryStatus.loading));

    try {
      final alreadyTaken = await examsRepository.hasCandidateAttempted(
        event.examId,
        event.uid,
      );
      emit(state.copyWith(hasAttempted: alreadyTaken));

      await emit.forEach<ExamModel>(
        examsRepository.getExam(event.examId),
        onData: (exam) => state.copyWith(
          status: ExamEntryStatus.success,
          exam: exam,
        ),
        onError: (error, _) => state.copyWith(
          status: ExamEntryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    } catch (e) {
      emit(state.copyWith(
        status: ExamEntryStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onStartAttemptRequested(
    ExamEntryStartAttemptRequested event,
    Emitter<ExamEntryState> emit,
  ) async {
    emit(state.copyWith(
      admissionStatus: ExamAdmissionStatus.starting,
      errorMessage: null,
    ));

    try {
      final result = await examsRepository.startAttempt(
        examId: event.examId,
        uid: event.uid,
        candidateName: event.candidateName,
      );

      switch (result) {
        case Admitted(:final attempt):
          emit(state.copyWith(
            admissionStatus: ExamAdmissionStatus.admitted,
            admittedAttempt: attempt,
            hasAttempted: true,
          ));
        case Full():
          emit(state.copyWith(
            admissionStatus: ExamAdmissionStatus.full,
          ));
        case AlreadyTaken():
          emit(state.copyWith(
            admissionStatus: ExamAdmissionStatus.alreadyTaken,
            hasAttempted: true,
          ));
      }
    } catch (e) {
      emit(state.copyWith(
        admissionStatus: ExamAdmissionStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}


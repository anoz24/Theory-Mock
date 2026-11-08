import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/exams_repository.dart';
import 'result_state.dart';

class ResultCubit extends Cubit<ResultState> {
  final ExamsRepository examsRepository;

  ResultCubit({required this.examsRepository}) : super(const ResultState());

  Future<void> loadResult({
    required String examId,
    required String uid,
  }) async {
    emit(state.copyWith(status: ResultStatus.loading));

    try {
      final exam = await examsRepository.getExam(examId).first;
      final attempt = await examsRepository.getAttempt(examId, uid).first;
      final questions = await examsRepository.getQuestionsForExam(examId);

      emit(state.copyWith(
        status: ResultStatus.success,
        examTitle: exam.title,
        showScore: exam.showScore,
        candidateName: attempt?.candidateName ?? 'Candidate',
        attemptStatus: attempt?.status ?? 'finished',
        score: attempt?.score ?? 0,
        totalQuestions: questions.length,
        durationSec: attempt?.durationSec ?? 0,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ResultStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}


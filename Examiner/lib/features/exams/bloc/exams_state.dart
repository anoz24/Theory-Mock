part of 'exams_bloc.dart';

enum ExamsStatus { initial, loading, success, failure }

class ExamsState extends Equatable {
  final ExamsStatus status;
  final List<ExamModel> exams;
  final String? errorMessage;
  final String? actionErrorMessage;

  const ExamsState({
    this.status = ExamsStatus.initial,
    this.exams = const [],
    this.errorMessage,
    this.actionErrorMessage,
  });

  ExamsState copyWith({
    ExamsStatus? status,
    List<ExamModel>? exams,
    String? errorMessage,
    String? actionErrorMessage,
  }) {
    return ExamsState(
      status: status ?? this.status,
      exams: exams ?? this.exams,
      errorMessage: errorMessage,
      actionErrorMessage: actionErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        exams,
        errorMessage,
        actionErrorMessage,
      ];
}


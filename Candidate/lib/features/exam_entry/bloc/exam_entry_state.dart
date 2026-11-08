part of 'exam_entry_bloc.dart';

enum ExamEntryStatus { initial, loading, success, failure }

enum ExamAdmissionStatus {
  idle,
  starting,
  admitted,
  full,
  alreadyTaken,
  error,
}

enum ExamButtonState {
  canStart,
  full,
  alreadyTaken,
}

class ExamEntryState extends Equatable {
  final ExamEntryStatus status;
  final ExamModel? exam;
  final bool hasAttempted;
  final ExamAdmissionStatus admissionStatus;
  final AttemptModel? admittedAttempt;
  final String? errorMessage;

  const ExamEntryState({
    this.status = ExamEntryStatus.initial,
    this.exam,
    this.hasAttempted = false,
    this.admissionStatus = ExamAdmissionStatus.idle,
    this.admittedAttempt,
    this.errorMessage,
  });

  ExamButtonState get buttonState {
    if (hasAttempted) return ExamButtonState.alreadyTaken;
    if (exam != null && exam!.isFull) return ExamButtonState.full;
    return ExamButtonState.canStart;
  }

  ExamEntryState copyWith({
    ExamEntryStatus? status,
    ExamModel? exam,
    bool? hasAttempted,
    ExamAdmissionStatus? admissionStatus,
    AttemptModel? admittedAttempt,
    String? errorMessage,
  }) {
    return ExamEntryState(
      status: status ?? this.status,
      exam: exam ?? this.exam,
      hasAttempted: hasAttempted ?? this.hasAttempted,
      admissionStatus: admissionStatus ?? this.admissionStatus,
      admittedAttempt: admittedAttempt ?? this.admittedAttempt,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        exam,
        hasAttempted,
        admissionStatus,
        admittedAttempt,
        errorMessage,
      ];
}


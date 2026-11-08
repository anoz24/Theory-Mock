part of 'exam_entry_bloc.dart';

abstract class ExamEntryEvent extends Equatable {
  const ExamEntryEvent();

  @override
  List<Object?> get props => [];
}

class ExamEntrySubscriptionRequested extends ExamEntryEvent {
  final String examId;
  final String uid;

  const ExamEntrySubscriptionRequested({
    required this.examId,
    required this.uid,
  });

  @override
  List<Object?> get props => [examId, uid];
}

class ExamEntryStartAttemptRequested extends ExamEntryEvent {
  final String examId;
  final String uid;
  final String candidateName;

  const ExamEntryStartAttemptRequested({
    required this.examId,
    required this.uid,
    required this.candidateName,
  });

  @override
  List<Object?> get props => [examId, uid, candidateName];
}


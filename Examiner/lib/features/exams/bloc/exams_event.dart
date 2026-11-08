part of 'exams_bloc.dart';

abstract class ExamsEvent extends Equatable {
  const ExamsEvent();

  @override
  List<Object?> get props => [];
}

class ExamsSubscriptionRequested extends ExamsEvent {
  final String categoryId;

  const ExamsSubscriptionRequested(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class ExamDeleteRequested extends ExamsEvent {
  final String examId;

  const ExamDeleteRequested(this.examId);

  @override
  List<Object?> get props => [examId];
}


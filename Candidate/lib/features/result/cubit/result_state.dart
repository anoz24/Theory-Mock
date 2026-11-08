import 'package:equatable/equatable.dart';

enum ResultStatus { initial, loading, success, failure }

class ResultState extends Equatable {
  final ResultStatus status;
  final String examTitle;
  final String candidateName;
  final String attemptStatus;
  final int score;
  final int totalQuestions;
  final bool showScore;
  final int durationSec;
  final String? errorMessage;

  const ResultState({
    this.status = ResultStatus.initial,
    this.examTitle = '',
    this.candidateName = '',
    this.attemptStatus = 'finished',
    this.score = 0,
    this.totalQuestions = 0,
    this.showScore = true,
    this.durationSec = 0,
    this.errorMessage,
  });

  String get formattedDuration {
    final mins = durationSec ~/ 60;
    final secs = durationSec % 60;
    return '${mins}m ${secs}s';
  }

  ResultState copyWith({
    ResultStatus? status,
    String? examTitle,
    String? candidateName,
    String? attemptStatus,
    int? score,
    int? totalQuestions,
    bool? showScore,
    int? durationSec,
    String? errorMessage,
  }) {
    return ResultState(
      status: status ?? this.status,
      examTitle: examTitle ?? this.examTitle,
      candidateName: candidateName ?? this.candidateName,
      attemptStatus: attemptStatus ?? this.attemptStatus,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      showScore: showScore ?? this.showScore,
      durationSec: durationSec ?? this.durationSec,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        examTitle,
        candidateName,
        attemptStatus,
        score,
        totalQuestions,
        showScore,
        durationSec,
        errorMessage,
      ];
}

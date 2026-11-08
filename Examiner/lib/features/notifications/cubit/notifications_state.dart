import 'package:equatable/equatable.dart';

class AttemptNotification extends Equatable {
  final String candidateName;
  final String examId;
  final int score;
  final int durationSec;
  final String status;
  final DateTime timestamp;

  const AttemptNotification({
    required this.candidateName,
    required this.examId,
    required this.score,
    required this.durationSec,
    required this.status,
    required this.timestamp,
  });

  String get formattedDuration {
    final mins = durationSec ~/ 60;
    final secs = durationSec % 60;
    return '${mins}m ${secs}s';
  }

  @override
  List<Object?> get props => [
        candidateName,
        examId,
        score,
        durationSec,
        status,
        timestamp,
      ];
}

class NotificationsState extends Equatable {
  final AttemptNotification? latestNotification;

  const NotificationsState({this.latestNotification});

  NotificationsState copyWith({
    AttemptNotification? latestNotification,
    bool clear = false,
  }) {
    return NotificationsState(
      latestNotification:
          clear ? null : (latestNotification ?? this.latestNotification),
    );
  }

  @override
  List<Object?> get props => [latestNotification];
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class AttemptModel extends Equatable {
  final String id;
  final String examId;
  final String candidateId;
  final String candidateName;
  final String status;
  final DateTime startedAt;
  final DateTime endsAt;
  final int currentIndex;
  final Map<String, bool> answers;
  final int score;
  final int durationSec;

  const AttemptModel({
    required this.id,
    required this.examId,
    required this.candidateId,
    required this.candidateName,
    required this.status,
    required this.startedAt,
    required this.endsAt,
    this.currentIndex = 0,
    this.answers = const {},
    this.score = 0,
    this.durationSec = 0,
  });

  AttemptModel copyWith({
    String? id,
    String? examId,
    String? candidateId,
    String? candidateName,
    String? status,
    DateTime? startedAt,
    DateTime? endsAt,
    int? currentIndex,
    Map<String, bool>? answers,
    int? score,
    int? durationSec,
  }) {
    return AttemptModel(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      candidateId: candidateId ?? this.candidateId,
      candidateName: candidateName ?? this.candidateName,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endsAt: endsAt ?? this.endsAt,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      score: score ?? this.score,
      durationSec: durationSec ?? this.durationSec,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'examId': examId,
      'candidateId': candidateId,
      'candidateName': candidateName,
      'status': status,
      'startedAt': Timestamp.fromDate(startedAt),
      'endsAt': Timestamp.fromDate(endsAt),
      'currentIndex': currentIndex,
      'answers': answers,
      'score': score,
      'durationSec': durationSec,
    };
  }

  factory AttemptModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    final rawAnswers = map['answers'] as Map? ?? {};
    final parsedAnswers = <String, bool>{};
    rawAnswers.forEach((key, value) {
      if (value is bool) {
        parsedAnswers[key.toString()] = value;
      }
    });

    return AttemptModel(
      id: id,
      examId: map['examId'] as String? ?? '',
      candidateId: map['candidateId'] as String? ?? '',
      candidateName: map['candidateName'] as String? ?? 'Candidate',
      status: map['status'] as String? ?? 'active',
      startedAt: parseTimestamp(map['startedAt']),
      endsAt: parseTimestamp(map['endsAt']),
      currentIndex: (map['currentIndex'] as num?)?.toInt() ?? 0,
      answers: parsedAnswers,
      score: (map['score'] as num?)?.toInt() ?? 0,
      durationSec: (map['durationSec'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        examId,
        candidateId,
        candidateName,
        status,
        startedAt,
        endsAt,
        currentIndex,
        answers,
        score,
        durationSec,
      ];
}


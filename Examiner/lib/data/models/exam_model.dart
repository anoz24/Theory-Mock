import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ExamModel extends Equatable {
  final String id;
  final String categoryId;
  final String title;
  final DateTime date;
  final int durationMin;
  final bool showScore;
  final Map<String, dynamic> activeSlots;

  const ExamModel({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.date,
    required this.durationMin,
    this.showScore = true,
    this.activeSlots = const {},
  });

  ExamModel copyWith({
    String? id,
    String? categoryId,
    String? title,
    DateTime? date,
    int? durationMin,
    bool? showScore,
    Map<String, dynamic>? activeSlots,
  }) {
    return ExamModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      date: date ?? this.date,
      durationMin: durationMin ?? this.durationMin,
      showScore: showScore ?? this.showScore,
      activeSlots: activeSlots ?? this.activeSlots,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'title': title,
      'date': Timestamp.fromDate(date),
      'durationMin': durationMin,
      'showScore': showScore,
      'activeSlots': activeSlots,
    };
  }

  factory ExamModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedDate;
    final rawDate = map['date'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else {
      parsedDate = DateTime.now();
    }

    return ExamModel(
      id: id,
      categoryId: map['categoryId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      date: parsedDate,
      durationMin: (map['durationMin'] as num?)?.toInt() ?? 30,
      showScore: map['showScore'] as bool? ?? true,
      activeSlots: Map<String, dynamic>.from(map['activeSlots'] as Map? ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        id,
        categoryId,
        title,
        date,
        durationMin,
        showScore,
        activeSlots,
      ];
}


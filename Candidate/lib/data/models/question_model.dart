import 'package:equatable/equatable.dart';

class QuestionModel extends Equatable {
  final String id;
  final String text;
  final bool correctAnswer;
  final int order;

  const QuestionModel({
    required this.id,
    required this.text,
    required this.correctAnswer,
    required this.order,
  });

  QuestionModel copyWith({
    String? id,
    String? text,
    bool? correctAnswer,
    int? order,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      text: text ?? this.text,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      order: order ?? this.order,
    );
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map, String id) {
    return QuestionModel(
      id: id,
      text: map['text'] as String? ?? '',
      correctAnswer: map['correctAnswer'] as bool? ?? true,
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'correctAnswer': correctAnswer,
      'order': order,
    };
  }

  @override
  List<Object?> get props => [id, text, correctAnswer, order];
}


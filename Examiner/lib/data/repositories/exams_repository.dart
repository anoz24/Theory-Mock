import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';

class ExamsRepository {
  final FirebaseFirestore _firestore;

  ExamsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<ExamModel>> getExamsForCategory(String categoryId) {
    return _firestore
        .collection('exams')
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) {
      final exams = snapshot.docs.map((doc) {
        return ExamModel.fromMap(doc.data(), doc.id);
      }).toList();

      exams.sort((a, b) => b.date.compareTo(a.date));
      return exams;
    });
  }

  Future<String> createExam({
    required ExamModel exam,
    required List<QuestionModel> questions,
  }) async {
    final examDocRef = _firestore.collection('exams').doc();
    final batch = _firestore.batch();

    batch.set(examDocRef, exam.toMap());

    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final qDocRef = examDocRef.collection('questions').doc();
      batch.set(qDocRef, {
        'text': q.text.trim(),
        'correctAnswer': q.correctAnswer,
        'order': i,
      });
    }

    await batch.commit();
    return examDocRef.id;
  }

  Future<void> deleteExam(String examId) async {
    final examRef = _firestore.collection('exams').doc(examId);
    final questionsQuery = await examRef.collection('questions').get();

    final batch = _firestore.batch();
    for (final qDoc in questionsQuery.docs) {
      batch.delete(qDoc.reference);
    }
    batch.delete(examRef);

    await batch.commit();
  }

  Future<List<QuestionModel>> getQuestionsForExam(String examId) async {
    final snapshot =
        await _firestore.collection('exams').doc(examId).collection('questions').get();

    final questions = snapshot.docs.map((doc) {
      return QuestionModel.fromMap(doc.data(), doc.id);
    }).toList();

    questions.sort((a, b) => a.order.compareTo(b.order));
    return questions;
  }
}


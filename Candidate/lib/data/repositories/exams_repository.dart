import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../models/attempt_model.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';

sealed class ExamAdmissionResult extends Equatable {
  const ExamAdmissionResult();

  @override
  List<Object?> get props => [];
}

class Admitted extends ExamAdmissionResult {
  final AttemptModel attempt;
  const Admitted(this.attempt);

  @override
  List<Object?> get props => [attempt];
}

class Full extends ExamAdmissionResult {
  const Full();
}

class AlreadyTaken extends ExamAdmissionResult {
  const AlreadyTaken();
}

class ExamsRepository {
  final FirebaseFirestore _firestore;

  ExamsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<ExamModel>> getExamsForCategory(
    String categoryId, {
    DateTime? dateFilter,
  }) {
    return _firestore
        .collection('exams')
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) {
      var exams = snapshot.docs
          .map((doc) => ExamModel.fromMap(doc.data(), doc.id))
          .toList();

      if (dateFilter != null) {
        final start = DateTime(
          dateFilter.year,
          dateFilter.month,
          dateFilter.day,
        );
        final end = start.add(const Duration(days: 1));
        exams = exams.where((e) {
          return !e.date.isBefore(start) && e.date.isBefore(end);
        }).toList();
      }

      exams.sort((a, b) => b.date.compareTo(a.date));
      return exams;
    });
  }

  Stream<ExamModel> getExam(String examId) {
    return _firestore
        .collection('exams')
        .doc(examId)
        .snapshots()
        .map((doc) => ExamModel.fromMap(doc.data() ?? {}, doc.id));
  }

  Future<List<QuestionModel>> getQuestionsForExam(String examId) async {
    final snapshot = await _firestore
        .collection('exams')
        .doc(examId)
        .collection('questions')
        .get();

    final questions = snapshot.docs
        .map((doc) => QuestionModel.fromMap(doc.data(), doc.id))
        .toList();

    questions.sort((a, b) => a.order.compareTo(b.order));
    return questions;
  }

  Future<bool> hasCandidateAttempted(String examId, String uid) async {
    final doc = await _firestore.collection('attempts').doc('${examId}_$uid').get();
    return doc.exists;
  }

  Stream<AttemptModel?> getAttempt(String examId, String uid) {
    return _firestore
        .collection('attempts')
        .doc('${examId}_$uid')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return AttemptModel.fromMap(doc.data() ?? {}, doc.id);
    });
  }

  Future<ExamAdmissionResult> startAttempt({
    required String examId,
    required String uid,
    required String candidateName,
  }) async {
    final attemptDocId = '${examId}_$uid';
    final attemptRef = _firestore.collection('attempts').doc(attemptDocId);
    final examRef = _firestore.collection('exams').doc(examId);

    return await _firestore.runTransaction<ExamAdmissionResult>((transaction) async {
      final attemptSnapshot = await transaction.get(attemptRef);
      if (attemptSnapshot.exists) {
        return const AlreadyTaken();
      }

      final examSnapshot = await transaction.get(examRef);
      if (!examSnapshot.exists) {
        throw Exception('Exam not found');
      }

      final examData = examSnapshot.data() ?? {};
      final durationMin = (examData['durationMin'] as num?)?.toInt() ?? 30;
      final rawSlots = Map<String, dynamic>.from(
        examData['activeSlots'] as Map? ?? {},
      );

      final now = DateTime.now();
      final validSlots = <String, dynamic>{};
      rawSlots.forEach((slotUid, endsAtVal) {
        DateTime? endsAt;
        if (endsAtVal is Timestamp) {
          endsAt = endsAtVal.toDate();
        } else if (endsAtVal is int) {
          endsAt = DateTime.fromMillisecondsSinceEpoch(endsAtVal);
        }
        if (endsAt != null && endsAt.isAfter(now)) {
          validSlots[slotUid] = endsAtVal;
        }
      });

      if (validSlots.length >= 2) {
        if (validSlots.length != rawSlots.length) {
          transaction.update(examRef, {'activeSlots': validSlots});
        }
        return const Full();
      }

      final startedAt = DateTime.now();
      final endsAt = startedAt.add(Duration(minutes: durationMin));
      validSlots[uid] = Timestamp.fromDate(endsAt);

      transaction.update(examRef, {'activeSlots': validSlots});

      final newAttempt = AttemptModel(
        id: attemptDocId,
        examId: examId,
        candidateId: uid,
        candidateName: candidateName,
        status: 'active',
        startedAt: startedAt,
        endsAt: endsAt,
        currentIndex: 0,
        answers: const {},
        score: 0,
        durationSec: 0,
      );

      transaction.set(attemptRef, newAttempt.toMap());

      return Admitted(newAttempt);
    });
  }

  Future<void> updateAttemptProgress({
    required String examId,
    required String uid,
    required Map<String, bool> answers,
    required int currentIndex,
  }) async {
    final attemptRef = _firestore.collection('attempts').doc('${examId}_$uid');
    await attemptRef.update({
      'answers': answers,
      'currentIndex': currentIndex,
    });
  }

  Future<void> finishAttempt({
    required String examId,
    required String uid,
    required int score,
    required int durationSec,
  }) async {
    final batch = _firestore.batch();
    final attemptRef = _firestore.collection('attempts').doc('${examId}_$uid');
    final examRef = _firestore.collection('exams').doc(examId);

    batch.update(attemptRef, {
      'status': 'finished',
      'score': score,
      'durationSec': durationSec,
    });

    batch.update(examRef, {
      'activeSlots.$uid': FieldValue.delete(),
    });

    await batch.commit();
  }

  Future<void> timeoutAttempt({
    required String examId,
    required String uid,
    required int score,
    required int durationSec,
  }) async {
    final batch = _firestore.batch();
    final attemptRef = _firestore.collection('attempts').doc('${examId}_$uid');
    final examRef = _firestore.collection('exams').doc(examId);

    batch.update(attemptRef, {
      'status': 'timeout',
      'score': score,
      'durationSec': durationSec,
    });

    batch.update(examRef, {
      'activeSlots.$uid': FieldValue.delete(),
    });

    await batch.commit();
  }

  Future<void> quitAttempt({
    required String examId,
    required String uid,
    required int durationSec,
  }) async {
    final batch = _firestore.batch();
    final attemptRef = _firestore.collection('attempts').doc('${examId}_$uid');
    final examRef = _firestore.collection('exams').doc(examId);

    batch.update(attemptRef, {
      'status': 'quit',
      'score': 0,
      'durationSec': durationSec,
    });

    batch.update(examRef, {
      'activeSlots.$uid': FieldValue.delete(),
    });

    await batch.commit();
  }
}


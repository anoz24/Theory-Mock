import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attempt_model.dart';

class AttemptsRepository {
  final FirebaseFirestore _firestore;

  AttemptsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<AttemptModel>> getActiveAttempts(String examId) {
    return _firestore
        .collection('attempts')
        .where('examId', isEqualTo: examId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AttemptModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<AttemptModel>> getFinishedAttempts(String examId) {
    return _firestore
        .collection('attempts')
        .where('examId', isEqualTo: examId)
        .where('status', whereIn: ['finished', 'timeout', 'quit'])
        .snapshots()
        .map((snapshot) {
      final attempts = snapshot.docs
          .map((doc) => AttemptModel.fromMap(doc.data(), doc.id))
          .toList();

      attempts.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return attempts;
    });
  }

  Stream<AttemptModel> get onAttemptCompleted {
    return _firestore
        .collection('attempts')
        .where('status', whereIn: ['finished', 'timeout'])
        .snapshots()
        .expand((snapshot) => snapshot.docChanges)
        .where((change) =>
            change.type == DocumentChangeType.added ||
            change.type == DocumentChangeType.modified)
        .map((change) =>
            AttemptModel.fromMap(change.doc.data() ?? {}, change.doc.id));
  }
}


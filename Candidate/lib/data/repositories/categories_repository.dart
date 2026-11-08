import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoriesRepository {
  final FirebaseFirestore _firestore;

  CategoriesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<CategoryModel>> getCategories() {
    return _firestore.collection('categories').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}


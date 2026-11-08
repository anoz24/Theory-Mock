import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoriesRepository {
  final FirebaseFirestore _firestore;

  CategoriesRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<CategoryModel>> getCategories() {
    return _firestore.collection('categories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CategoryModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<CategoryModel> createCategory({
    required String name,
    required File imageFile,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final imageBase64 = base64Encode(bytes);

    final docRef = await _firestore.collection('categories').add({
      'name': name.trim(),
      'imageBase64': imageBase64,
    });

    return CategoryModel(
      id: docRef.id,
      name: name.trim(),
      imageBase64: imageBase64,
    );
  }

  Future<void> deleteCategory(String categoryId) async {
    final examsQuery = await _firestore
        .collection('exams')
        .where('categoryId', isEqualTo: categoryId)
        .get();

    final batch = _firestore.batch();

    for (final examDoc in examsQuery.docs) {
      final questionsQuery =
          await examDoc.reference.collection('questions').get();
      for (final qDoc in questionsQuery.docs) {
        batch.delete(qDoc.reference);
      }
      batch.delete(examDoc.reference);
    }

    final categoryRef = _firestore.collection('categories').doc(categoryId);
    batch.delete(categoryRef);

    await batch.commit();
  }
}

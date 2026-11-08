import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final String imageBase64;
  final String imageUrl;

  const CategoryModel({
    required this.id,
    required this.name,
    this.imageBase64 = '',
    this.imageUrl = '',
  });

  bool get hasImage => imageBase64.isNotEmpty || imageUrl.isNotEmpty;

  CategoryModel copyWith({
    String? id,
    String? name,
    String? imageBase64,
    String? imageUrl,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageBase64: imageBase64 ?? this.imageBase64,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageBase64': imageBase64,
      'imageUrl': imageUrl,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      name: map['name'] as String? ?? '',
      imageBase64: map['imageBase64'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, imageBase64, imageUrl];
}

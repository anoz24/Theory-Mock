part of 'categories_bloc.dart';

abstract class CategoriesEvent extends Equatable {
  const CategoriesEvent();

  @override
  List<Object?> get props => [];
}

class CategoriesSubscriptionRequested extends CategoriesEvent {
  const CategoriesSubscriptionRequested();
}

class CategoryCreateRequested extends CategoriesEvent {
  final String name;
  final File imageFile;

  const CategoryCreateRequested({
    required this.name,
    required this.imageFile,
  });

  @override
  List<Object?> get props => [name, imageFile];
}

class CategoryDeleteRequested extends CategoriesEvent {
  final CategoryModel category;

  const CategoryDeleteRequested(this.category);

  @override
  List<Object?> get props => [category];
}


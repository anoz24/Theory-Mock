part of 'categories_bloc.dart';

enum CategoriesStatus { initial, loading, success, failure }
enum CategoryActionStatus { initial, loading, success, failure }

class CategoriesState extends Equatable {
  final CategoriesStatus status;
  final List<CategoryModel> categories;
  final String? errorMessage;
  final CategoryActionStatus actionStatus;
  final String? actionErrorMessage;

  const CategoriesState({
    this.status = CategoriesStatus.initial,
    this.categories = const [],
    this.errorMessage,
    this.actionStatus = CategoryActionStatus.initial,
    this.actionErrorMessage,
  });

  CategoriesState copyWith({
    CategoriesStatus? status,
    List<CategoryModel>? categories,
    String? errorMessage,
    CategoryActionStatus? actionStatus,
    String? actionErrorMessage,
  }) {
    return CategoriesState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      errorMessage: errorMessage,
      actionStatus: actionStatus ?? this.actionStatus,
      actionErrorMessage: actionErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        categories,
        errorMessage,
        actionStatus,
        actionErrorMessage,
      ];
}


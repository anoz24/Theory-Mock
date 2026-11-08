part of 'browse_bloc.dart';

enum BrowseStatus { initial, loading, success, failure }

class BrowseState extends Equatable {
  final BrowseStatus categoriesStatus;
  final List<CategoryModel> categories;
  final BrowseStatus examsStatus;
  final List<ExamModel> exams;
  final String? selectedCategoryId;
  final DateTime? selectedDate;
  final String? errorMessage;

  const BrowseState({
    this.categoriesStatus = BrowseStatus.initial,
    this.categories = const [],
    this.examsStatus = BrowseStatus.initial,
    this.exams = const [],
    this.selectedCategoryId,
    this.selectedDate,
    this.errorMessage,
  });

  BrowseState copyWith({
    BrowseStatus? categoriesStatus,
    List<CategoryModel>? categories,
    BrowseStatus? examsStatus,
    List<ExamModel>? exams,
    String? selectedCategoryId,
    DateTime? selectedDate,
    bool clearDateFilter = false,
    String? errorMessage,
  }) {
    return BrowseState(
      categoriesStatus: categoriesStatus ?? this.categoriesStatus,
      categories: categories ?? this.categories,
      examsStatus: examsStatus ?? this.examsStatus,
      exams: exams ?? this.exams,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedDate: clearDateFilter ? null : (selectedDate ?? this.selectedDate),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        categoriesStatus,
        categories,
        examsStatus,
        exams,
        selectedCategoryId,
        selectedDate,
        errorMessage,
      ];
}


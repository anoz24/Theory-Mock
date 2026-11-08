import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/exam_model.dart';
import '../../../data/repositories/categories_repository.dart';
import '../../../data/repositories/exams_repository.dart';

part 'browse_event.dart';
part 'browse_state.dart';

class BrowseBloc extends Bloc<BrowseEvent, BrowseState> {
  final CategoriesRepository categoriesRepository;
  final ExamsRepository examsRepository;

  BrowseBloc({
    required this.categoriesRepository,
    required this.examsRepository,
  }) : super(const BrowseState()) {
    on<BrowseCategoriesSubscriptionRequested>(_onCategoriesSubscriptionRequested);
    on<BrowseExamsSubscriptionRequested>(_onExamsSubscriptionRequested);
    on<BrowseDateFilterChanged>(_onDateFilterChanged);
  }

  Future<void> _onCategoriesSubscriptionRequested(
    BrowseCategoriesSubscriptionRequested event,
    Emitter<BrowseState> emit,
  ) async {
    emit(state.copyWith(categoriesStatus: BrowseStatus.loading));
    await emit.forEach<List<CategoryModel>>(
      categoriesRepository.getCategories(),
      onData: (categories) => state.copyWith(
        categoriesStatus: BrowseStatus.success,
        categories: categories,
      ),
      onError: (error, _) => state.copyWith(
        categoriesStatus: BrowseStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  Future<void> _onExamsSubscriptionRequested(
    BrowseExamsSubscriptionRequested event,
    Emitter<BrowseState> emit,
  ) async {
    emit(state.copyWith(
      examsStatus: BrowseStatus.loading,
      selectedCategoryId: event.categoryId,
    ));

    await emit.forEach<List<ExamModel>>(
      examsRepository.getExamsForCategory(
        event.categoryId,
        dateFilter: state.selectedDate,
      ),
      onData: (exams) => state.copyWith(
        examsStatus: BrowseStatus.success,
        exams: exams,
      ),
      onError: (error, _) => state.copyWith(
        examsStatus: BrowseStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  Future<void> _onDateFilterChanged(
    BrowseDateFilterChanged event,
    Emitter<BrowseState> emit,
  ) async {
    emit(state.copyWith(
      selectedDate: event.date,
      clearDateFilter: event.date == null,
    ));

    if (state.selectedCategoryId != null) {
      emit(state.copyWith(examsStatus: BrowseStatus.loading));
      await emit.forEach<List<ExamModel>>(
        examsRepository.getExamsForCategory(
          state.selectedCategoryId!,
          dateFilter: event.date,
        ),
        onData: (exams) => state.copyWith(
          examsStatus: BrowseStatus.success,
          exams: exams,
        ),
        onError: (error, _) => state.copyWith(
          examsStatus: BrowseStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}


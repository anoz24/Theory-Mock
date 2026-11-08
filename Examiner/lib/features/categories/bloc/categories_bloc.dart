import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/categories_repository.dart';

part 'categories_event.dart';
part 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final CategoriesRepository categoriesRepository;

  CategoriesBloc({required this.categoriesRepository})
      : super(const CategoriesState()) {
    on<CategoriesSubscriptionRequested>(_onSubscriptionRequested);
    on<CategoryCreateRequested>(_onCreateRequested);
    on<CategoryDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onSubscriptionRequested(
    CategoriesSubscriptionRequested event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(state.copyWith(status: CategoriesStatus.loading));
    await emit.forEach<List<CategoryModel>>(
      categoriesRepository.getCategories(),
      onData: (categories) => state.copyWith(
        status: CategoriesStatus.success,
        categories: categories,
      ),
      onError: (error, _) => state.copyWith(
        status: CategoriesStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  Future<void> _onCreateRequested(
    CategoryCreateRequested event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(state.copyWith(
      actionStatus: CategoryActionStatus.loading,
      actionErrorMessage: null,
    ));
    try {
      await categoriesRepository.createCategory(
        name: event.name,
        imageFile: event.imageFile,
      );
      emit(state.copyWith(actionStatus: CategoryActionStatus.success));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: CategoryActionStatus.failure,
        actionErrorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteRequested(
    CategoryDeleteRequested event,
    Emitter<CategoriesState> emit,
  ) async {
    try {
      await categoriesRepository.deleteCategory(event.category.id);
    } catch (e) {
      emit(state.copyWith(
        actionStatus: CategoryActionStatus.failure,
        actionErrorMessage: e.toString(),
      ));
    }
  }
}

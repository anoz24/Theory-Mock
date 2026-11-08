part of 'browse_bloc.dart';

abstract class BrowseEvent extends Equatable {
  const BrowseEvent();

  @override
  List<Object?> get props => [];
}

class BrowseCategoriesSubscriptionRequested extends BrowseEvent {
  const BrowseCategoriesSubscriptionRequested();
}

class BrowseExamsSubscriptionRequested extends BrowseEvent {
  final String categoryId;

  const BrowseExamsSubscriptionRequested(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class BrowseDateFilterChanged extends BrowseEvent {
  final DateTime? date;

  const BrowseDateFilterChanged(this.date);

  @override
  List<Object?> get props => [date];
}


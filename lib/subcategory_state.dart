import 'main.dart';

abstract class SubcategoryState {}

class SubcategoryInitial extends SubcategoryState {}

class SubcategoryLoading extends SubcategoryState {}

class SubcategoryLoaded extends SubcategoryState {
  final List<Subcategory> subcategories;
  SubcategoryLoaded(this.subcategories);
}

class SubcategoryError extends SubcategoryState {
  final String message;
  SubcategoryError(this.message);
}

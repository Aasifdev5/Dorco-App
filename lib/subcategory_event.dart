abstract class SubcategoryEvent {}

class LoadSubcategories extends SubcategoryEvent {
  final int categoryId;
  LoadSubcategories(this.categoryId);
}

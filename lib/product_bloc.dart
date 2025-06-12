import 'package:flutter_bloc/flutter_bloc.dart';
import 'product.dart';
import 'product_repository.dart';

// Events
abstract class ProductEvent {}

class LoadProducts extends ProductEvent {
  final int categoryId;
  final int subcategoryId;
  final int startIndex;

  LoadProducts({
    required this.categoryId,
    required this.subcategoryId,
    required this.startIndex,
  });
}

// States
class ProductState {
  final List<Product> products;
  final bool hasMore;
  final int currentCategoryId;
  final int currentSubcategoryId;

  ProductState({
    required this.products,
    required this.hasMore,
    required this.currentCategoryId,
    required this.currentSubcategoryId,
  });

  ProductState copyWith({
    List<Product>? products,
    bool? hasMore,
    int? currentCategoryId,
    int? currentSubcategoryId,
  }) {
    return ProductState(
      products: products ?? this.products,
      hasMore: hasMore ?? this.hasMore,
      currentCategoryId: currentCategoryId ?? this.currentCategoryId,
      currentSubcategoryId: currentSubcategoryId ?? this.currentSubcategoryId,
    );
  }
}

// Bloc
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;
  static const int _limit = 10; // Number of products per page

  ProductBloc(this.repository)
    : super(
        ProductState(
          products: [],
          hasMore: true,
          currentCategoryId: 0,
          currentSubcategoryId: 0,
        ),
      ) {
    on<LoadProducts>(_onLoadProducts);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    try {
      // If the category or subcategory has changed, reset the product list
      if (event.categoryId != state.currentCategoryId ||
          event.subcategoryId != state.currentSubcategoryId) {
        emit(
          state.copyWith(
            products: [],
            hasMore: true,
            currentCategoryId: event.categoryId,
            currentSubcategoryId: event.subcategoryId,
          ),
        );
      }

      // If we already have all products, don't fetch more
      if (!state.hasMore) return;

      final products = await repository.fetchProducts(
        event.categoryId,
        event.subcategoryId,
        event.startIndex,
        _limit,
      );

      // Update the state with the new products
      final updatedProducts =
          event.startIndex == 0 ? products : [...state.products, ...products];
      emit(
        state.copyWith(
          products: updatedProducts,
          hasMore:
              products.length ==
              _limit, // If we get fewer products than the limit, there are no more
          currentCategoryId: event.categoryId,
          currentSubcategoryId: event.subcategoryId,
        ),
      );
    } catch (e) {
      print('Error loading products: $e');
      // You can emit an error state here if needed
    }
  }
}

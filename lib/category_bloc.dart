import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'category_event.dart';
import 'category_state.dart';
import 'main.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc() : super(CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());
    try {
      final response = await http.get(
        Uri.parse('https://dorca.shop/api/categories'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final categories = data
            .map((category) => Category.fromJson(category))
            .toList();
        emit(CategoryLoaded(categories));
      } else {
        emit(
          CategoryError('Failed to load categories: ${response.statusCode}'),
        );
      }
    } catch (e) {
      emit(CategoryError('Error loading categories: $e'));
    }
  }
}

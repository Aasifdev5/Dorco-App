import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'subcategory_event.dart';
import 'subcategory_state.dart';
import 'main.dart';

class SubcategoryBloc extends Bloc<SubcategoryEvent, SubcategoryState> {
  SubcategoryBloc() : super(SubcategoryInitial()) {
    on<LoadSubcategories>(_onLoadSubcategories);
  }

  Future<void> _onLoadSubcategories(
    LoadSubcategories event,
    Emitter<SubcategoryState> emit,
  ) async {
    emit(SubcategoryLoading());
    try {
      final response = await http.get(
        Uri.parse('https://dorca.shop/api/subcategories/${event.categoryId}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Subcategory> subcategories =
            (data is List ? data : data['data'] as List)
                .map((subcategory) => Subcategory.fromJson(subcategory))
                .toList();
        emit(SubcategoryLoaded(subcategories));
      } else {
        emit(
          SubcategoryError(
            'Failed to load subcategories: ${response.statusCode}',
          ),
        );
      }
    } catch (e) {
      emit(SubcategoryError('Error loading subcategories: $e'));
    }
  }
}

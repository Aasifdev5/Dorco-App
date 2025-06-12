import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product.dart';

class ProductRepository {
  Future<List<Product>> fetchProducts(
    int categoryId,
    int subcategoryId,
    int startIndex,
    int limit,
  ) async {
    try {
      // Calculate the page number based on startIndex and limit
      final page = (startIndex ~/ limit) + 1;
      final response = await http.get(
        Uri.parse(
          'https://dorca.shop/api/products/$categoryId/$subcategoryId?page=$page&per_page=$limit',
        ),
      );

      print(
        'Products API Status for category $categoryId, subcategory $subcategoryId: ${response.statusCode}',
      );
      print('Products API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((product) => Product.fromJson(product)).toList();
        } else if (data['data'] is List) {
          // Handle paginated response with a "data" field
          return (data['data'] as List)
              .map((product) => Product.fromJson(product))
              .toList();
        } else {
          throw Exception(
            'Expected a list of products, got: ${data.runtimeType}',
          );
        }
      } else {
        throw Exception(
          'Failed to load products: ${response.statusCode}, Response: ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching products: $e');
      rethrow;
    }
  }
}

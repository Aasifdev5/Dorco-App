class Product {
  final String id;
  final String name;
  final String description;
  final String code;
  final String image;
  final int categoryId;
  final int subcategoryId; // Added subcategoryId

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.code,
    required this.image,
    required this.categoryId,
    required this.subcategoryId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    String imageUrl;
    if (json['image'] != null) {
      String imagePath = json['image'] as String;
      if (imagePath.startsWith('http')) {
        imageUrl = imagePath;
      } else {
        imagePath = imagePath.startsWith('/') ? imagePath : '/$imagePath';
        imageUrl = 'https://dorca.shop$imagePath';
      }
    } else {
      imageUrl = 'https://picsum.photos/200/200';
    }

    return Product(
      id: (json['id'] as int).toString(),
      name: json['name'] as String? ?? 'No name',
      description: json['description'] as String? ?? 'No description',
      code: json['code'] as String? ?? 'N/A',
      image: imageUrl,
      categoryId: json['category_id'] as int? ?? 0,
      subcategoryId: json['subcategory_id'] as int? ?? 0, // Added subcategoryId
    );
  }
}

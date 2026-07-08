import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.title,
    required super.price,
    required super.unit,
    required super.category,
    required super.imageUrl,
    required super.stock,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      price: json['price'] is num 
          ? (json['price'] as num).toDouble() 
          : double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      unit: json['unit'] as String? ?? '',
      category: (json['category_name'] ?? json['category']) as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      stock: (json['stock_quantity'] ?? json['stock']) as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'unit': unit,
      'category': category,
      'image_url': imageUrl,
      'stock': stock,
    };
  }
}

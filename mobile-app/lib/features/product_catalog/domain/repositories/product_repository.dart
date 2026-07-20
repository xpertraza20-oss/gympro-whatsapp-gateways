import '../entities/product.dart';
import '../entities/category.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts({
    required int page,
    required int limit,
    String? search,
    int? categoryId,
  });

  Future<List<Category>> getCategories();

  Future<Product> createProduct({
    required String title,
    required String description,
    required double price,
    required double? salePrice,
    required String unit,
    required int stockQuantity,
    required int? categoryId,
    required String? imageUrl,
  });
}

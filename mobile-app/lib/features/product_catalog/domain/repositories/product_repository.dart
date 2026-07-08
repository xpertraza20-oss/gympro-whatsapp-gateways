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
}

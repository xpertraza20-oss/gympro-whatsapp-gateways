import '../entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts({
    required int page,
    required int limit,
  });
}

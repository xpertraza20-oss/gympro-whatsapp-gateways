import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductsUseCase {
  final ProductRepository repository;

  GetProductsUseCase(this.repository);

  Future<List<Product>> call({
    required int page,
    int limit = 10,
  }) async {
    return await repository.getProducts(
      page: page,
      limit: limit,
    );
  }
}

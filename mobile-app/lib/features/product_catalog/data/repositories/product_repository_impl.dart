import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_data_source.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Product>> getProducts({
    required int page,
    required int limit,
  }) async {
    // Simply fetch models from data source and return as domain entities list
    return await remoteDataSource.fetchProducts(
      page: page,
      limit: limit,
    );
  }
}

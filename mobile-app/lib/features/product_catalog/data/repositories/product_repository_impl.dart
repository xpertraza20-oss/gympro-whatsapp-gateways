import '../../domain/entities/product.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_data_source.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Product>> getProducts({
    required int page,
    required int limit,
    String? search,
    int? categoryId,
  }) async {
    // Simply fetch models from data source and return as domain entities list
    return await remoteDataSource.fetchProducts(
      page: page,
      limit: limit,
      search: search,
      categoryId: categoryId,
    );
  }

  @override
  Future<List<Category>> getCategories() async {
    return await remoteDataSource.fetchCategories();
  }
}

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

  @override
  Future<Product> createProduct({
    required String title,
    required String description,
    required double price,
    required double? salePrice,
    required String unit,
    required int stockQuantity,
    required int? categoryId,
    required String? imageUrl,
  }) async {
    return await remoteDataSource.createProduct(
      title: title,
      description: description,
      price: price,
      salePrice: salePrice,
      unit: unit,
      stockQuantity: stockQuantity,
      categoryId: categoryId,
      imageUrl: imageUrl,
    );
  }
}

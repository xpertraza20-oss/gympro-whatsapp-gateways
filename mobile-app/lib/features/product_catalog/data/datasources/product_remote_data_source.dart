import 'package:dio/dio.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> fetchProducts({
    required int page,
    required int limit,
    String? search,
    int? categoryId,
  });

  Future<List<CategoryModel>> fetchCategories();

  Future<ProductModel> createProduct({
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

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final Dio dio;

  ProductRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ProductModel>> fetchProducts({
    required int page,
    required int limit,
    String? search,
    int? categoryId,
  }) async {
    try {
      // Simulate real GET request to backend products endpoint
      // GET /api/v1/products?page=1&limit=10&search=keyword&category_id=X
      final response = await dio.get(
        '/api/v1/products',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (categoryId != null) 'category_id': categoryId,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => ProductModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
        );
      }
    } catch (e) {
      print("[RemoteDataSource] Fetch products failed, error: $e");
      rethrow;
    }
  }

  @override
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await dio.get('/api/v1/categories');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => CategoryModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
        );
      }
    } catch (e) {
      print("[RemoteDataSource] Categories fetch failed, error: $e");
      rethrow;
    }
  }

  @override
  Future<ProductModel> createProduct({
    required String title,
    required String description,
    required double price,
    required double? salePrice,
    required String unit,
    required int stockQuantity,
    required int? categoryId,
    required String? imageUrl,
  }) async {
    try {
      final response = await dio.post(
        '/api/v1/products',
        data: {
          'title': title,
          'description': description,
          'price': price,
          if (salePrice != null) 'sale_price': salePrice,
          'unit': unit,
          'stock_quantity': stockQuantity,
          if (categoryId != null) 'category_id': categoryId,
          if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return ProductModel.fromJson(data as Map<String, dynamic>);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
        );
      }
    } catch (e) {
      print("[RemoteDataSource] Create product failed, error: $e");
      rethrow;
    }
  }
}

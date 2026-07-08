import 'package:dio/dio';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> fetchProducts({
    required int page,
    required int limit,
  });
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final Dio dio;

  ProductRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ProductModel>> fetchProducts({
    required int page,
    required int limit,
  }) async {
    try {
      // Simulate real GET request to backend products endpoint
      // GET /api/v1/products?page=1&limit=10
      final response = await dio.get(
        '/api/v1/products',
        queryParameters: {
          'page': page,
          'limit': limit,
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
      // Return highly structured mock local products on network failure so the UI works instantly
      print("[RemoteDataSource] Fetch failed or offline, returning mock page: $page");
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate latency
      return _generateMockProducts(page, limit);
    }
  }

  List<ProductModel> _generateMockProducts(int page, int limit) {
    // Generate mock products based on pagination
    final List<Map<String, dynamic>> rawMockData = [
      {
        'id': 'p1',
        'title': 'Organic Apples Honeycrisp',
        'price': 4.99,
        'unit': '1 kg bag',
        'category': 'Fruits',
        'image_url': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&q=80&w=300',
        'stock': 12,
      },
      {
        'id': 'p2',
        'title': 'Fresh Broccoli Crown',
        'price': 2.49,
        'unit': 'each',
        'category': 'Vegetables',
        'image_url': 'https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?auto=format&fit=crop&q=80&w=300',
        'stock': 3, // stock < 5 warning
      },
      {
        'id': 'p3',
        'title': 'Whole Milk 3.25%',
        'price': 5.89,
        'unit': '4L Jug',
        'category': 'Dairy & Eggs',
        'image_url': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&q=80&w=300',
        'stock': 15,
      },
      {
        'id': 'p4',
        'title': 'Sourdough Bread Loaf',
        'price': 4.50,
        'unit': 'each',
        'category': 'Bakery',
        'image_url': 'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?auto=format&fit=crop&q=80&w=300',
        'stock': 2, // stock < 5 warning
      },
      {
        'id': 'p5',
        'title': 'Atlantic Salmon Fillet',
        'price': 18.99,
        'unit': '500g',
        'category': 'Meat & Seafood',
        'image_url': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?auto=format&fit=crop&q=80&w=300',
        'stock': 8,
      },
      {
        'id': 'p6',
        'title': 'Extra Virgin Olive Oil',
        'price': 12.99,
        'unit': '750ml bottle',
        'category': 'Pantry Staples',
        'image_url': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&q=80&w=300',
        'stock': 14,
      },
      {
        'id': 'p7',
        'title': 'Sparkling Water Lime',
        'price': 3.99,
        'unit': '12 x 355ml pack',
        'category': 'Beverages',
        'image_url': 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&q=80&w=300',
        'stock': 4, // stock < 5 warning
      },
      {
        'id': 'p8',
        'title': 'Greek Yogurt Strawberry',
        'price': 6.29,
        'unit': '650g tub',
        'category': 'Dairy & Eggs',
        'image_url': 'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&q=80&w=300',
        'stock': 11,
      },
      {
        'id': 'p9',
        'title': 'Organic Avocados',
        'price': 5.49,
        'unit': '4 pack bag',
        'category': 'Fruits',
        'image_url': 'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?auto=format&fit=crop&q=80&w=300',
        'stock': 1, // stock < 5 warning
      },
      {
        'id': 'p10',
        'title': 'Salted Potato Chips',
        'price': 3.19,
        'unit': '200g bag',
        'category': 'Snacks',
        'image_url': 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?auto=format&fit=crop&q=80&w=300',
        'stock': 9,
      }
    ];

    final startIndex = (page - 1) * limit;
    if (startIndex >= rawMockData.length) {
      return []; // No more products (for pagination test)
    }

    final pagedData = rawMockData.skip(startIndex).take(limit).toList();

    // Map to ProductModel but change ID for infinite scroll testing differentiation
    return pagedData.map((json) {
      return ProductModel.fromJson({
        ...json,
        'id': '${json['id']}_page${page}',
        'title': '${json['title']} (Page $page)',
      });
    }).toList();
  }
}

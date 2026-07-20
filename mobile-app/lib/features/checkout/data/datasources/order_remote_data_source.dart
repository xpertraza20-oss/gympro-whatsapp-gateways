import 'package:dio/dio.dart';

abstract class OrderRemoteDataSource {
  Future<Map<String, dynamic>> placeOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required double totalAmount,
    required String paymentMethod,
  });

  Future<List<dynamic>> fetchOrderHistory();

  Future<Map<String, dynamic>> fetchOrderById(int id);

  Future<Map<String, dynamic>> cancelOrder(int id, String reason);

  Future<void> deleteOrder(int id);

  Future<Map<String, dynamic>> updateShopkeeperOrderStatus(int orderId, String action);

  Future<Map<String, dynamic>> updateRiderOrderStatus(int orderId, String action);

  Future<List<dynamic>> fetchOrderHistoryTimeline(int orderId);

  Future<Map<String, dynamic>> requestCodApproval({required int orderId, required double amount});

  Future<Map<String, dynamic>?> fetchCodApprovalStatus(int orderId);

  Future<double> fetchRiderCodLimit();
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final Dio dio;

  OrderRemoteDataSourceImpl({required this.dio});

  @override
  Future<Map<String, dynamic>> placeOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required double totalAmount,
    required String paymentMethod,
  }) async {
    try {
      final response = await dio.post(
        '/api/v1/orders',
        data: {
          'items': items,
          'delivery_address': deliveryAddress,
          'total_amount': totalAmount,
          'payment_method': paymentMethod,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
        );
      }
    } catch (e) {
      print("[OrderRemoteDataSource] Order placement failed: $e");
      rethrow;
    }
  }

  @override
  Future<List<dynamic>> fetchOrderHistory() async {
    try {
      final response = await dio.get('/api/v1/orders/history');
      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
        );
      }
    } catch (e) {
      print("[OrderRemoteDataSource] Fetch history failed: $e");
      // Fallback local mock history on offline/failure
      return _generateMockHistory();
    }
  }

  @override
  Future<Map<String, dynamic>> fetchOrderById(int id) async {
    try {
      final response = await dio.get('/api/v1/orders/$id');
      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
        );
      }
    } catch (e) {
      print("[OrderRemoteDataSource] Fetch order by id failed: $e");
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> cancelOrder(int id, String reason) async {
    try {
      final response = await dio.put(
        '/api/v1/orders/$id/cancel',
        data: {'reason': reason},
      );
      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
        );
      }
    } catch (e) {
      print("[OrderRemoteDataSource] Cancel order failed: $e");
      rethrow;
    }
  }

  @override
  Future<void> deleteOrder(int id) async {
    try {
      final response = await dio.delete('/api/v1/orders/$id');
      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
        );
      }
    } catch (e) {
      print("[OrderRemoteDataSource] Delete order failed: $e");
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> updateShopkeeperOrderStatus(int orderId, String action) async {
    try {
      final response = await dio.post('/api/v1/shopkeeper/orders/$orderId/$action');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'] ?? response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
        );
      }
    } catch (e) {
      print("[OrderRemoteDataSource] Update shopkeeper order status failed: $e");
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> updateRiderOrderStatus(int orderId, String action) async {
    try {
      final response = await dio.post('/api/v1/rider/orders/$orderId/$action');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'] ?? response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
        );
      }
    } catch (e) {
      print("[OrderRemoteDataSource] Update rider order status failed: $e");
      rethrow;
    }
  }

  @override
  Future<List<dynamic>> fetchOrderHistoryTimeline(int orderId) async {
    try {
      final response = await dio.get('/api/v1/orders/$orderId/history');
      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
        );
      }
    } catch (e) {
      print("[OrderRemoteDataSource] Fetch order timeline failed: $e");
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> requestCodApproval({
    required int orderId,
    required double amount,
  }) async {
    try {
      final response = await dio.post(
        '/api/v1/rider/cod/request-approval',
        data: {'order_id': orderId, 'amount': amount},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'] ?? response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
        );
      }
    } catch (e) {
      print("[OrderRemoteDataSource] COD approval request failed: $e");
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchCodApprovalStatus(int orderId) async {
    try {
      final response = await dio.get('/api/v1/rider/cod/approval-status/$orderId');
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print("[OrderRemoteDataSource] Fetch COD approval status failed: $e");
      return null;
    }
  }

  @override
  Future<double> fetchRiderCodLimit() async {
    try {
      final response = await dio.get('/api/v1/rider/cod-limit');
      if (response.statusCode == 200) {
        return double.tryParse(
              response.data['data']['cod_limit']?.toString() ?? '5000',
            ) ??
            5000.0;
      }
      return 5000.0;
    } catch (e) {
      print("[OrderRemoteDataSource] Fetch rider COD limit failed: $e");
      return 5000.0;
    }
  }

  List<dynamic> _generateMockHistory() {
    return [
      {
        'id': 101,
        'delivery_address': 'Mock Address, G-11, Islamabad',
        'total_amount': 24.50,
        'payment_method': 'COD',
        'status': 'Confirmed',
        'created_at': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
        'items': [
          {
            'product': {
              'id': 'p1',
              'title': 'Organic Apples Honeycrisp',
              'price': 4.99,
              'unit': '1 kg bag',
              'category': 'Fruits',
              'image_url': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&q=80&w=300',
              'stock': 12,
            },
            'quantity': 2,
          }
        ]
      }
    ];
  }
}

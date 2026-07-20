import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_data_source.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;

  OrderRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Map<String, dynamic>> placeOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required double totalAmount,
    required String paymentMethod,
  }) async {
    return await remoteDataSource.placeOrder(
      items: items,
      deliveryAddress: deliveryAddress,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
    );
  }

  @override
  Future<List<dynamic>> getOrderHistory() async {
    return await remoteDataSource.fetchOrderHistory();
  }

  @override
  Future<Map<String, dynamic>> getOrderById(int id) async {
    return await remoteDataSource.fetchOrderById(id);
  }

  @override
  Future<Map<String, dynamic>> cancelOrder(int id, String reason) async {
    return await remoteDataSource.cancelOrder(id, reason);
  }

  @override
  Future<void> deleteOrder(int id) async {
    await remoteDataSource.deleteOrder(id);
  }

  @override
  Future<Map<String, dynamic>> updateShopkeeperOrderStatus(int orderId, String action) async {
    return await remoteDataSource.updateShopkeeperOrderStatus(orderId, action);
  }

  @override
  Future<Map<String, dynamic>> updateRiderOrderStatus(int orderId, String action) async {
    return await remoteDataSource.updateRiderOrderStatus(orderId, action);
  }

  @override
  Future<List<dynamic>> getOrderHistoryTimeline(int orderId) async {
    return await remoteDataSource.fetchOrderHistoryTimeline(orderId);
  }

  @override
  Future<Map<String, dynamic>> requestCodApproval({
    required int orderId,
    required double amount,
  }) async {
    return await remoteDataSource.requestCodApproval(orderId: orderId, amount: amount);
  }

  @override
  Future<Map<String, dynamic>?> getCodApprovalStatus(int orderId) async {
    return await remoteDataSource.fetchCodApprovalStatus(orderId);
  }

  @override
  Future<double> getRiderCodLimit() async {
    return await remoteDataSource.fetchRiderCodLimit();
  }
}


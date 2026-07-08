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
}

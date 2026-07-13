abstract class OrderRepository {
  Future<Map<String, dynamic>> placeOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required double totalAmount,
    required String paymentMethod,
  });

  Future<List<dynamic>> getOrderHistory();

  Future<Map<String, dynamic>> getOrderById(int id);

  Future<Map<String, dynamic>> cancelOrder(int id, String reason);

  Future<void> deleteOrder(int id);
}

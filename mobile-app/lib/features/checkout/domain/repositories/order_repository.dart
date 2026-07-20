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

  Future<Map<String, dynamic>> updateShopkeeperOrderStatus(int orderId, String action);

  Future<Map<String, dynamic>> updateRiderOrderStatus(int orderId, String action);

  Future<List<dynamic>> getOrderHistoryTimeline(int orderId);

  /// Submit a COD approval request to admin for a high-value order
  Future<Map<String, dynamic>> requestCodApproval({required int orderId, required double amount});

  /// Get the COD approval status for a specific order
  Future<Map<String, dynamic>?> getCodApprovalStatus(int orderId);

  /// Get the authenticated rider's own COD limit
  Future<double> getRiderCodLimit();
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import 'order_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  void _fetchHistory() {
    context.read<OrderBloc>().add(const FetchOrderHistoryEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Order History', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
          }

          if (state is OrderError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text('Failed to load orders: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchHistory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is OrderHistoryLoaded) {
            final orders = state.orders;

            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text(
                      'No orders yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your order history will show up here.',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _fetchHistory();
              },
              color: const Color(0xFF10B981),
              child: ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: orders.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final orderId = order['id'];
                  final status = order['status'] ?? 'Pending';
                  final totalAmount = order['total_amount'] is num 
                      ? (order['total_amount'] as num).toDouble() 
                      : double.tryParse(order['total_amount']?.toString() ?? '') ?? 0.0;

                  // Date Formatter
                  final dateStr = order['created_at'] != null
                      ? DateTime.parse(order['created_at']).toLocal().toString().substring(0, 16)
                      : '';

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order #$orderId',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937)),
                              ),
                              _buildStatusBadge(status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dateStr,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                          const Divider(height: 24),
                          Text(
                            'Address: ${order['delivery_address']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '\$${totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF10B981)),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderTrackingScreen(orderId: orderId),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF10B981),
                                  surfaceTintColor: Colors.white,
                                  elevation: 0,
                                  side: const BorderSide(color: Color(0xFF10B981)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text('Track Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }

          return const Center(child: Text('Load order history...'));
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        break;
      case 'confirmed':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        break;
      case 'dispatched':
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple.shade800;
        break;
      case 'delivered':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        break;
      default:
        bgColor = Colors.grey.shade50;
        textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

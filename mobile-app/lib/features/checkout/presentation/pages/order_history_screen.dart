import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  void _showCancelDialog(BuildContext context, int orderId) {
    final TextEditingController reasonCtrl = TextEditingController();
    final primaryColor = Theme.of(context).primaryColor;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please provide a reason for cancelling this order:',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'e.g., Changed my mind, ordered wrong item...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Go Back', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = reasonCtrl.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a cancellation reason.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogCtx);
                context.read<OrderBloc>().add(CancelOrderEvent(orderId: orderId, reason: reason));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Order History', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderCancelSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: primaryColor,
              ),
            );
            _fetchHistory();
          }
        },
        child: BlocBuilder<OrderBloc, OrderState>(
          builder: (context, state) {
            if (state is OrderLoading) {
              return Center(child: CircularProgressIndicator(color: primaryColor));
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
                          backgroundColor: primaryColor,
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
                color: primaryColor,
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

                    // Parse items safely
                    List<dynamic> orderItems = [];
                    if (order['items'] is List) {
                      orderItems = order['items'];
                    } else if (order['items'] is String) {
                      try {
                        orderItems = jsonDecode(order['items']);
                      } catch (_) {}
                    }

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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                            if (orderItems.isNotEmpty) ...[
                              const Divider(height: 24),
                              const Text(
                                'Items Ordered:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF374151)),
                              ),
                              const SizedBox(height: 8),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: orderItems.length,
                                itemBuilder: (context, itemIndex) {
                                  final item = orderItems[itemIndex];
                                  final title = item['title'] ?? item['product']?['title'] ?? 'Product';
                                  final price = item['price'] is num 
                                      ? (item['price'] as num).toDouble() 
                                      : double.tryParse(item['price']?.toString() ?? '') ?? 0.0;
                                  final quantity = item['quantity'] ?? 1;
                                  final imageUrl = item['image_url'] ?? item['product']?['image_url'] ?? '';
                                  final unit = item['unit'] ?? item['product']?['unit'] ?? '';

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            color: Colors.grey[100],
                                            child: imageUrl.isNotEmpty
                                                ? CachedNetworkImage(
                                                    imageUrl: imageUrl,
                                                    fit: BoxFit.cover,
                                                    errorWidget: (context, url, error) => const Icon(Icons.shopping_basket, size: 20, color: Colors.grey),
                                                  )
                                                : const Icon(Icons.shopping_basket, size: 20, color: Colors.grey),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1F2937)),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 1),
                                              Text(
                                                '${unit.isNotEmpty ? "$unit • " : ""}Qty: $quantity',
                                                style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Rs. ${(price * quantity).toStringAsFixed(0)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1F2937)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Rs. ${totalAmount.toStringAsFixed(0)}',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor),
                                ),
                                Row(
                                  children: [
                                    if (status.toLowerCase() == 'pending' || status.toLowerCase() == 'confirmed') ...[
                                      OutlinedButton(
                                        onPressed: () => _showCancelDialog(context, orderId),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.redAccent,
                                          side: const BorderSide(color: Colors.redAccent),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => OrderTrackingScreen(orderId: orderId),
                                          ),
                                        ).then((_) {
                                          _fetchHistory();
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: primaryColor,
                                        surfaceTintColor: Colors.white,
                                        elevation: 0,
                                        side: BorderSide(color: primaryColor),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                      child: const Text('Track Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
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
            // If the bloc is in any other state (e.g. OrderTrackingLoaded or OrderPlacedSuccess),
            // trigger history reload on next frame and show loading spinner.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fetchHistory();
            });
            return Center(child: CircularProgressIndicator(color: primaryColor));
          },
        ),
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
      case 'cancelled':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
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

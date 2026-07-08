import 'package:flutter/material.dart';
import 'order_tracking_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final orderId = order['id'] ?? 0;
    final totalAmount = order['total_amount'] is num 
        ? (order['total_amount'] as num).toDouble() 
        : double.tryParse(order['total_amount']?.toString() ?? '') ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Success Icon / Animation Circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFA7F3D0), width: 4),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 80,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Order Placed Successfully!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Thank you for shopping with FreshCart. Your order has been placed and is being processed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Invoice detail summary card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Order ID', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        Text(
                          '#$orderId',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937), fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment Mode', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        Text(
                          order['payment_method'] ?? 'COD',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937), fontSize: 14),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Bill Paid', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        Text(
                          '\$${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderTrackingScreen(orderId: orderId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Track My Order',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                    ),
                  ),
                  child: const Text(
                    'Back to Shopping',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

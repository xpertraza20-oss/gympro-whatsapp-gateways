import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Timer? _pollingTimer;
  Map<String, dynamic>? _cachedOrder;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Check if bloc already holds tracking data for this order
    final currentState = context.read<OrderBloc>().state;
    if (currentState is OrderTrackingLoaded && 
        (currentState.order['id'] == widget.orderId || 
         currentState.order['id'].toString() == widget.orderId.toString())) {
      _cachedOrder = currentState.order;
    }

    _fetchStatus();
    // Setup polling every 8 seconds to sync status from server silently
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      _fetchStatus();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _fetchStatus() {
    context.read<OrderBloc>().add(FetchOrderTrackingEvent(widget.orderId));
  }

  int _getStatusStep(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'confirmed':
        return 1;
      case 'dispatched':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Track Order #${widget.orderId}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderLoading) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is OrderTrackingLoaded && 
              (state.order['id'] == widget.orderId || 
               state.order['id'].toString() == widget.orderId.toString())) {
            setState(() {
              _cachedOrder = state.order;
              _errorMessage = null;
              _isLoading = false;
            });
          } else if (state is OrderError) {
            setState(() {
              _isLoading = false;
              if (_cachedOrder == null) {
                _errorMessage = state.message;
              }
            });
            _pollingTimer?.cancel(); // Cancel polling on error to prevent infinite reload spamming
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}'), backgroundColor: Colors.redAccent),
            );
          } else {
            // Ignore unrelated states (like history loaded)
            setState(() {
              _isLoading = false;
            });
          }
        },
        child: Builder(
          builder: (context) {
            // Render from cache if available to prevent UI refresh flicker/load spinner
            if (_cachedOrder != null) {
              final order = _cachedOrder!;
              final currentStatus = order['status'] ?? 'Pending';
              final activeStep = _getStatusStep(currentStatus);
              final totalAmount = order['total_amount'] is num 
                  ? (order['total_amount'] as num).toDouble() 
                  : double.tryParse(order['total_amount']?.toString() ?? '') ?? 0.0;

              return RefreshIndicator(
                onRefresh: () async {
                  _fetchStatus();
                },
                color: primaryColor,
                child: ListView(
                  padding: const EdgeInsets.all(24.0),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    // Order Card Header info
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Estimated Delivery',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                              ),
                              Text(
                                'COD Payment',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Today, 4:00 PM - 6:00 PM',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Amount to Pay', style: TextStyle(color: Colors.grey, fontSize: 14)),
                              Text(
                                'Rs. ${totalAmount.toStringAsFixed(0)}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Timeline Steps
                    const Text(
                      'Order Status Timeline',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                    ),
                    const SizedBox(height: 24),

                    _buildTimelineStep(
                      index: 0,
                      activeStep: activeStep,
                      title: 'Order Placed',
                      subtitle: 'We have received your order request.',
                      icon: Icons.receipt_long,
                    ),
                    _buildTimelineStep(
                      index: 1,
                      activeStep: activeStep,
                      title: 'Order Confirmed',
                      subtitle: 'Store has accepted and is preparing items.',
                      icon: Icons.check_circle_outline,
                    ),
                    _buildTimelineStep(
                      index: 2,
                      activeStep: activeStep,
                      title: 'Order Dispatched',
                      subtitle: 'Delivery rider is on the way to your address.',
                      icon: Icons.delivery_dining,
                    ),
                    _buildTimelineStep(
                      index: 3,
                      activeStep: activeStep,
                      title: 'Delivered',
                      subtitle: 'Rider successfully delivered your package.',
                      icon: Icons.home_work_outlined,
                      isLast: true,
                    ),

                    const SizedBox(height: 40),
                    
                    // Back home button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (_errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text('Failed to load tracking: $_errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchStatus,
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

            return Center(child: CircularProgressIndicator(color: primaryColor));
          },
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required int index,
    required int activeStep,
    required String title,
    required String subtitle,
    required IconData icon,
    bool isLast = false,
  }) {
    final isDone = activeStep >= index;
    final isCurrent = activeStep == index;
    final primaryColor = Theme.of(context).primaryColor;
    final color = isDone 
        ? primaryColor 
        : Colors.grey.shade300;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left timeline line and circle
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFFE8F5E9) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: isCurrent ? 3 : 2,
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDone ? primaryColor : Colors.grey,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: isDone && activeStep > index ? primaryColor : Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 16),

        // Text details
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDone ? const Color(0xFF1F2937) : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDone ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

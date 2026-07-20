import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/phone_auth_bloc.dart';
import '../../../checkout/presentation/bloc/order_bloc.dart';
import '../../../checkout/presentation/bloc/order_event.dart';
import '../../../checkout/presentation/bloc/order_state.dart';
import '../../../product_catalog/domain/repositories/product_repository.dart';

// ─── DUMMY ORDER MODEL ────────────────────────────────────────────────────────
class ShopkeeperOrder {
  final String id;
  final String customerName;
  final String deliveryArea;
  final String timestamp;
  final List<String> items;
  final double totalAmount;
  final String paymentMethod;
  String status; // 'Pending', 'Preparing', 'Looking for Rider', 'Ready', 'Rejected'
  int prepTimeMinutes;

  ShopkeeperOrder({
    required this.id,
    required this.customerName,
    required this.deliveryArea,
    required this.timestamp,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    this.status = 'Pending',
    this.prepTimeMinutes = 0,
  });
}

// ─── MAIN SHOPKEEPER DASHBOARD ────────────────────────────────────────────────
class ShopkeeperDashboard extends StatefulWidget {
  const ShopkeeperDashboard({super.key});

  @override
  State<ShopkeeperDashboard> createState() => _ShopkeeperDashboardState();
}

class _ShopkeeperDashboardState extends State<ShopkeeperDashboard>
    with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  bool _isBroadcasting = false;
  String _broadcastingOrderId = '';

  // Pulsing glow animation controller for new alert
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Dummy list of shopkeeper orders
  final List<ShopkeeperOrder> _orders = [
    ShopkeeperOrder(
      id: '1029',
      customerName: 'Ahmed Raza',
      deliveryArea: 'Block D, Model Town, Lahore',
      timestamp: 'Just now',
      items: ['2x Organic Red Apples', '1x Farm Fresh Eggs', '1x Premium Milk Pasteurized'],
      totalAmount: 1000.0,
      paymentMethod: 'COD',
      status: 'pending',
    ),
    ShopkeeperOrder(
      id: '1025',
      customerName: 'Zainab Bibi',
      deliveryArea: 'Gulberg III, Lahore',
      timestamp: '25 mins ago',
      items: ['5x Plain Bread Large', '2x Chocolate Croissant'],
      totalAmount: 1270.0,
      paymentMethod: 'COD',
      status: 'preparing',
      prepTimeMinutes: 20,
    ),
    ShopkeeperOrder(
      id: '1020',
      customerName: 'Kamil Khan',
      deliveryArea: 'Defence Phase 5, Lahore',
      timestamp: '2 hours ago',
      items: ['1x Digital Body Thermometer', '2x Panadol Extra Tablets'],
      totalAmount: 830.0,
      paymentMethod: 'Prepaid',
      status: 'ready_for_pickup',
    ),
  ];

  static const _primaryColor = Color(0xFFBA5F06); // Orange/Amber Theme
  static const _primaryLight = Color(0xFFD97706);
  static const _bgColor = Color(0xFFFDFBFA);

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 3.0, end: 12.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _showPrepTimeDialog(ShopkeeperOrder order) {
    int selectedMinutes = 20;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Estimated Prep Time',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How many minutes are required to prepare this order?',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [10, 20, 30, 45].map((mins) {
                      final isSel = selectedMinutes == mins;
                      return ChoiceChip(
                        label: Text('$mins mins'),
                        selected: isSel,
                        selectedColor: _primaryColor.withOpacity(0.2),
                        checkmarkColor: _primaryColor,
                        labelStyle: TextStyle(
                          color: isSel ? _primaryColor : Colors.black87,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              selectedMinutes = mins;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateShopkeeperStatus(order, 'accept');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<OrderBloc, OrderState>(
          listener: (context, state) {
            if (state is OrderAcceptedSuccess) {
              setState(() {
                final order = _orders.firstWhere((o) => o.id == state.orderId);
                order.status = 'Preparing';
                order.prepTimeMinutes = state.prepTimeMinutes;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order ${state.orderId} accepted! (${state.prepTimeMinutes} mins prep time)'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is FindingRiderProgress) {
              setState(() {
                _isBroadcasting = true;
                _broadcastingOrderId = state.orderId;
              });
            } else if (state is FindingRiderSuccess) {
              setState(() {
                _isBroadcasting = false;
                final order = _orders.firstWhere((o) => o.id == state.orderId);
                order.status = 'Looking for Rider';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Broadcast success! Searching for nearest rider for Order ${state.orderId}...'),
                  backgroundColor: _primaryColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is OrderError) {
              setState(() {
                _isBroadcasting = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.message}'),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        BlocListener<PhoneAuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthInitial) {
              Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
            }
          },
        ),
      ],
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: _bgColor,
            body: IndexedStack(
              index: _currentNavIndex,
              children: [
                _buildActiveOrdersTab(),
                _buildMyMenuTab(),
                _buildProfileTab(),
              ],
            ),
            bottomNavigationBar: _buildBottomNav(),
          ),
          if (_isBroadcasting)
            Container(
              color: Colors.black.withOpacity(0.75),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(28),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Radar/Sonar wave simulator
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 90,
                              height: 90,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor.withOpacity(0.5)),
                              ),
                            ),
                            const SizedBox(
                              width: 70,
                              height: 70,
                              child: CircularProgressIndicator(
                                strokeWidth: 6,
                                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                              ),
                            ),
                            const Icon(Icons.radar_rounded, color: _primaryColor, size: 36),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Broadcasting Order...',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1F2937)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Broadcasting order #$_broadcastingOrderId to nearby active riders...',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ACTIVE ORDERS TAB
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildActiveOrdersTab() {
    final pendingOrders = _orders.where((o) => o.status.toLowerCase() == 'pending').toList();
    final processOrders = _orders.where((o) => o.status.toLowerCase() != 'pending' && o.status.toLowerCase() != 'rejected').toList();

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Incoming Orders',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937), fontSize: 18),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _primaryColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checking for new orders...'), behavior: SnackBarBehavior.floating),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Metrics Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.notifications_active_rounded,
                      title: 'New Requests',
                      value: '${pendingOrders.length}',
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.autorenew_rounded,
                      title: 'Active Prep',
                      value: '${processOrders.where((o) => o.status == 'Preparing').length}',
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section Header: New incoming
          if (pendingOrders.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'NEW ORDERS (REQUIRES ACTION)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.redAccent, letterSpacing: 0.8),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildPendingOrderCard(pendingOrders[index]),
                childCount: pendingOrders.length,
              ),
            ),
          ],

          // Section Header: Processing / Accepted
          if (processOrders.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'IN PREPARATION / READY',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildActiveOrderCard(processOrders[index]),
                childCount: processOrders.length,
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // Pulsing Glowing Pending Order Card
  Widget _buildPendingOrderCard(ShopkeeperOrder order) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.08),
                blurRadius: _glowAnimation.value,
                spreadRadius: _glowAnimation.value / 4,
              ),
            ],
            border: Border.all(color: Colors.redAccent.withOpacity(0.2), width: 1.5),
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID + Timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.id,
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
                      child: const Text('NEW ALERT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ),
                  ],
                ),
                Text(order.timestamp, style: const TextStyle(fontSize: 12, color: Colors.black38, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),

            // Customer Name & Area
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text(
                  order.customerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.deliveryArea,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFF3F4F6)),

            // Items List
            const Text('Items Ordered:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 4),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '• $item',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF374151), fontWeight: FontWeight.w500),
                  ),
                )),

            const Divider(height: 24, color: Color(0xFFF3F4F6)),

            // Bill & COD highlight
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Bill', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
                    Row(
                      children: [
                        Text(
                          'Rs. ${order.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _primaryColor),
                        ),
                        const SizedBox(width: 8),
                        if (order.paymentMethod == 'COD')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                            child: const Text('COD', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFB45309))),
                          ),
                      ],
                    ),
                  ],
                ),
                // Action Buttons Accept/Reject
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => _updateShopkeeperStatus(order, 'reject'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      child: const Text('Reject', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _showPrepTimeDialog(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        elevation: 0,
                      ),
                      child: const Text('Accept Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Active / Preparing Order Card
  Widget _buildActiveOrderCard(ShopkeeperOrder order) {
    Color statusColor = _primaryColor;
    if (order.status == 'Ready') statusColor = Colors.green;
    if (order.status == 'Looking for Rider') statusColor = Colors.indigo;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${order.id}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  order.status.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(order.deliveryArea, style: const TextStyle(fontSize: 12, color: Colors.black45)),
          if (order.prepTimeMinutes > 0 && order.status == 'Preparing') ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: _primaryColor),
                const SizedBox(width: 4),
                Text(
                  'Prep Time: ${order.prepTimeMinutes} mins',
                  style: const TextStyle(fontSize: 12, color: _primaryColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Bill: Rs. ${order.totalAmount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              if (order.status.toLowerCase() == 'accepted')
                ElevatedButton(
                  onPressed: () => _updateShopkeeperStatus(order, 'prepare'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Start Preparing', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                )
              else if (order.status.toLowerCase() == 'preparing')
                ElevatedButton(
                  onPressed: () => _updateShopkeeperStatus(order, 'ready'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Ready for Pickup', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                )
              else if (order.status.toLowerCase() == 'ready_for_pickup')
                const Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: Colors.indigo, size: 16),
                    SizedBox(width: 4),
                    Text('Waiting for Rider Assign', style: TextStyle(color: Colors.indigo, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                )
              else
                Row(
                  children: [
                    const Icon(Icons.done_all_rounded, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(order.status.toUpperCase(), style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.black38, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MY MENU TAB
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildMyMenuTab() {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Store Inventory', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937), fontSize: 18)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: () => _showAddProductSheet(context), icon: const Icon(Icons.add_rounded, color: _primaryColor)),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.inventory_2_outlined, size: 40, color: _primaryColor),
            ),
            const SizedBox(height: 16),
            const Text('Your store has 142 items online', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937))),
            const SizedBox(height: 4),
            const Text('Manage categories and pricing', style: TextStyle(fontSize: 12, color: Colors.black38)),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PROFILE TAB
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildProfileTab() {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Store Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937), fontSize: 18)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => context.read<PhoneAuthBloc>().add(LogoutEvent()),
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
            label: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(color: _primaryColor, shape: BoxShape.circle),
                  child: const Icon(Icons.store_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Al-Fatah Store Manager', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Merchant ID: #SHP-9923', style: TextStyle(fontSize: 12, color: Colors.black38)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...[
            ('Store Timings', Icons.access_time_rounded),
            ('Earnings & Payments', Icons.wallet_rounded),
            ('Notification Settings', Icons.notifications_active_outlined),
            ('Support & Help', Icons.help_outline_rounded),
          ].map((item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                color: Colors.white,
                child: ListTile(
                  leading: Icon(item.$2, color: _primaryColor),
                  title: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black26),
                  onTap: () {},
                ),
              )),
        ],
      ),
    );
  }

  void _showAddProductSheet(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final unitController = TextEditingController(text: '1 kg');
    final stockController = TextEditingController(text: '50');
    int? selectedCategoryId = 1; // Default to Fruits
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.between,
                      children: [
                        const Text(
                          'Add New Product',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1F2937)),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Product Title',
                        hintText: 'e.g. Organic Red Apples',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe item details, weight, packaging...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Price (PKR)',
                              hintText: '250',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: unitController,
                            decoration: const InputDecoration(
                              labelText: 'Unit / Weight',
                              hintText: '1 kg',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: stockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Stock Quantity',
                              hintText: '50',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedCategoryId,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('Fruits')),
                              DropdownMenuItem(value: 2, child: Text('Vegetables')),
                              DropdownMenuItem(value: 3, child: Text('Dairy & Eggs')),
                              DropdownMenuItem(value: 4, child: Text('Bakery')),
                              DropdownMenuItem(value: 5, child: Text('Meat & Seafood')),
                              DropdownMenuItem(value: 6, child: Text('Pantry Staples')),
                              DropdownMenuItem(value: 7, child: Text('Beverages')),
                              DropdownMenuItem(value: 8, child: Text('Snacks')),
                            ],
                            onChanged: (val) {
                              setSheetState(() {
                                selectedCategoryId = val;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSaving ? null : () async {
                          final title = titleController.text.trim();
                          final desc = descController.text.trim();
                          final priceStr = priceController.text.trim();
                          final unit = unitController.text.trim();
                          final stockStr = stockController.text.trim();

                          if (title.isEmpty || priceStr.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all required fields')),
                            );
                            return;
                          }

                          final price = double.tryParse(priceStr) ?? 0.0;
                          final stock = int.tryParse(stockStr) ?? 0;

                          setSheetState(() {
                            isSaving = true;
                          });

                          try {
                            final repo = RepositoryProvider.of<ProductRepository>(context);
                            await repo.createProduct(
                              title: title,
                              description: desc,
                              price: price,
                              salePrice: null,
                              unit: unit,
                              stockQuantity: stock,
                              categoryId: selectedCategoryId,
                              imageUrl: '',
                            );

                            Navigator.pop(context); // Close bottom sheet
                            _showApprovalWaitingDialog();
                          } catch (e) {
                            setSheetState(() {
                              isSaving = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to add product: $e')),
                            );
                          }
                        },
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Submit for Approval',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showApprovalWaitingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.shade200, width: 2),
                ),
                child: const Icon(
                  Icons.hourglass_empty_rounded,
                  color: Colors.amber,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Waiting for Admin Approval',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.black,
                  fontSize: 18,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your product has been submitted successfully. It will be visible to customers once the admin approves it.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Understood',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateShopkeeperStatus(ShopkeeperOrder order, String action) async {
    final orderId = int.tryParse(order.id) ?? 101;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Updating order status on server...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final repo = RepositoryProvider.of<OrderRepository>(context);
      await repo.updateShopkeeperOrderStatus(orderId, action);
      
      setState(() {
        if (action == 'accept') {
          order.status = 'accepted';
        } else if (action == 'reject') {
          order.status = 'rejected';
        } else if (action == 'prepare') {
          order.status = 'preparing';
        } else if (action == 'ready') {
          order.status = 'ready_for_pickup';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated successfully to ${order.status}!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() {
        if (action == 'accept') {
          order.status = 'accepted';
        } else if (action == 'reject') {
          order.status = 'rejected';
        } else if (action == 'prepare') {
          order.status = 'preparing';
        } else if (action == 'ready') {
          order.status = 'ready_for_pickup';
        }
      });
      print("[ShopkeeperDashboard] Error updating status via API, applied fallback: $e");
    }
  }

  // Bottom Navigation Bar
  Widget _buildBottomNav() {
    const tabs = [
      {'icon': Icons.receipt_long_rounded, 'label': 'Orders'},
      {'icon': Icons.menu_book_rounded, 'label': 'My Menu'},
      {'icon': Icons.storefront_rounded, 'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -2))],
        border: const Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final isActive = _currentNavIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentNavIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tabs[i]['icon'] as IconData,
                        color: isActive ? _primaryColor : const Color(0xFF9CA3AF),
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tabs[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive ? _primaryColor : const Color(0xFF9CA3AF),
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

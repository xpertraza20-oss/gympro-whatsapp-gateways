import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/phone_auth_bloc.dart';
import '../../../checkout/presentation/bloc/order_bloc.dart';
import '../../../checkout/presentation/bloc/order_event.dart';
import '../../../checkout/presentation/bloc/order_state.dart';
import '../../../checkout/domain/repositories/order_repository.dart';
import 'active_delivery_screen.dart';

// ─── MAP PAINTER FOR PREMIUM SIMULATED GOOGLE MAP ────────────────────────────
class MapPainter extends CustomPainter {
  final Offset riderPosition;
  final Offset shopPosition;
  final bool showRoute;
  final double animationProgress;

  MapPainter({
    required this.riderPosition,
    required this.shopPosition,
    required this.showRoute,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF1F5F9); // Light slate/grey map background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final roadBorderPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw stylized grid layout of roads
    final List<Path> roads = [];
    
    // Main avenue (horizontal)
    roads.add(Path()
      ..moveTo(-50, size.height * 0.4)
      ..lineTo(size.width + 50, size.height * 0.4));
    
    // 2nd avenue (horizontal)
    roads.add(Path()
      ..moveTo(-50, size.height * 0.75)
      ..lineTo(size.width + 50, size.height * 0.75));

    // Vertical streets
    roads.add(Path()
      ..moveTo(size.width * 0.25, -50)
      ..lineTo(size.width * 0.25, size.height + 50));
    roads.add(Path()
      ..moveTo(size.width * 0.75, -50)
      ..lineTo(size.width * 0.75, size.height + 50));

    // Diagonal street connecting rider to shop
    roads.add(Path()
      ..moveTo(riderPosition.dx, riderPosition.dy)
      ..lineTo(shopPosition.dx, shopPosition.dy));

    for (var path in roads) {
      canvas.drawPath(path, roadBorderPaint);
      canvas.drawPath(path, roadPaint);
    }

    // Draw green parks/landscapes
    final parkPaint = Paint()..color = const Color(0xFFDCFCE7); // Light green
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(16, 16, size.width * 0.2, size.height * 0.2),
        const Radius.circular(16),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.5, size.height * 0.5, size.width * 0.4, size.height * 0.2),
        const Radius.circular(16),
      ),
      parkPaint,
    );

    // Draw route path if accepted or receiving
    if (showRoute) {
      final routePaint = Paint()
        ..color = const Color(0xFF0F766E) // Teal/Green theme
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final routePath = Path()
        ..moveTo(riderPosition.dx, riderPosition.dy)
        ..lineTo(shopPosition.dx, shopPosition.dy);

      canvas.drawPath(routePath, routePaint);
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.riderPosition != riderPosition ||
        oldDelegate.shopPosition != shopPosition ||
        oldDelegate.showRoute != showRoute ||
        oldDelegate.animationProgress != animationProgress;
  }
}

// ─── RIDER DASHBOARD ──────────────────────────────────────────────────────────
class RiderDashboard extends StatefulWidget {
  const RiderDashboard({super.key});

  @override
  State<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isOnline = false;
  bool _hasIncomingRequest = false;
  bool _isAccepted = false;
  bool _isAdminApproving = false;
  double _riderCodLimit = 5000.0; // fetched from backend in initState
  
  // Animation controllers
  late AnimationController _ringController;
  late Animation<double> _ringScaleAnimation;
  late Animation<double> _ringOpacityAnimation;

  late AnimationController _mapAnimController;

  // Custom positioning offsets
  Offset _riderOffset = const Offset(100, 450);
  Offset _shopOffset = const Offset(280, 220);

  // Incoming Request Parameters (codAmount > 5000 triggers the security rule)
  final String _incomingOrderId = 'GFG-1029';
  final String _shopName = 'Al-Fatah Premium Store';
  final String _shopArea = 'Block D, Model Town, Lahore';
  final String _customerArea = 'Model Town Lahore - Sector D';
  final double _codAmount = 5200.0;
  final double _estimatedEarning = 180.0;

  static const _primaryColor = Color(0xFF0F766E); // Teal theme for Rider
  static const _accentColor = Color(0xFF14B8A6);

  @override
  void initState() {
    super.initState();
    // Urgent Ringing bottom sheet animation
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _ringScaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeInOut),
    );
    _ringOpacityAnimation = Tween<double>(begin: 0.2, end: 0.8).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeInOut),
    );

    _mapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // Fetch the real COD limit for this rider from backend
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final repo = RepositoryProvider.of<OrderRepository>(context);
        final limit = await repo.getRiderCodLimit();
        if (mounted) setState(() => _riderCodLimit = limit);
      } catch (e) {
        print('[RiderDashboard] Could not fetch COD limit: $e — using default Rs.5000');
      }
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
    _mapAnimController.dispose();
    super.dispose();
  }

  void _toggleOnlineStatus(bool val) {
    setState(() {
      _isOnline = val;
      if (_isOnline) {
        // Trigger simulated incoming request after 2.5 seconds of going online
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted && _isOnline && !_isAccepted && _currentIndex == 0) {
            setState(() {
              _hasIncomingRequest = true;
              _ringController.repeat(reverse: true);
            });
          }
        });
      } else {
        _hasIncomingRequest = false;
        _ringController.stop();
      }
    });
  }

  Future<void> _navigateToActiveDelivery() async {
    _ringController.stop();
    
    final orderIdInt = int.tryParse(_incomingOrderId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1029;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Accepting job and assigning rider...'), duration: Duration(seconds: 1)),
    );

    try {
      final repo = RepositoryProvider.of<OrderRepository>(context);
      await repo.updateRiderOrderStatus(orderIdInt, 'accept');
    } catch (e) {
      print("[RiderDashboard] API Accept failed, applied offline fallback: $e");
    }

    setState(() {
      _isAccepted = true;
      _hasIncomingRequest = false;
    });

    final details = {
      'orderId': _incomingOrderId,
      'shopName': _shopName,
      'shopArea': _shopArea,
      'exactAddress': 'Flat 4B, Sector Z, Model Town, Lahore',
      'customerPhone': '+92 300 123 4567',
      'customerName': 'Ahmed Raza',
      'codAmount': _codAmount,
      'earnings': _estimatedEarning,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveDeliveryScreen(deliveryDetails: details),
      ),
    ).then((value) {
      if (value == true) {
        // Reset state after delivery completion
        setState(() {
          _isAccepted = false;
          _hasIncomingRequest = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PhoneAuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: _primaryColor,
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        backgroundColor: Colors.white,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            activeIcon: Icon(Icons.map_rounded, color: _primaryColor),
            label: 'Map & Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            activeIcon: Icon(Icons.bar_chart_rounded, color: _primaryColor),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            activeIcon: Icon(Icons.person_rounded, color: _primaryColor),
            label: 'Profile',
          ),
        ],
      ),
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is AdminApprovalProgress) {
            setState(() {
              _isAdminApproving = true;
            });
          } else if (state is AdminApprovalSuccess) {
            setState(() {
              _isAdminApproving = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Admin Approval Granted! Accepting Delivery...'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _navigateToActiveDelivery();
          } else if (state is OrderError) {
            setState(() {
              _isAdminApproving = false;
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
        child: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: [
                _buildMapTab(),
                _buildEarningsTab(),
                _buildProfileTab(),
              ],
            ),

            // 4. ADMIN APPROVAL LOADER OVERLAY
            if (_isAdminApproving)
              Container(
                color: Colors.black.withOpacity(0.75),
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.all(28),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    color: Colors.white,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: _primaryColor),
                          SizedBox(height: 24),
                          Text(
                            'Waiting for Admin clearance...',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1F2937)),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Evaluating COD limit override authorization...',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

  // ─── TAB 1: MAP & INCOMING JOBS ─────────────────────────────────────────────
  Widget _buildMapTab() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Rider Map',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1F2937), fontSize: 18),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          Row(
            children: [
              Text(
                _isOnline ? 'ONLINE' : 'OFFLINE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: _isOnline ? _primaryColor : Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: _isOnline,
                onChanged: _toggleOnlineStatus,
                activeColor: _primaryColor,
                activeTrackColor: _primaryColor.withOpacity(0.2),
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade200,
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // 1. SIMULATED MAP BACKGROUND
          LayoutBuilder(
            builder: (context, constraints) {
              // Recalculate relative coordinates
              _riderOffset = Offset(constraints.maxWidth * 0.3, constraints.maxHeight * 0.7);
              _shopOffset = Offset(constraints.maxWidth * 0.7, constraints.maxHeight * 0.35);

              return AnimatedBuilder(
                animation: _mapAnimController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: MapPainter(
                      riderPosition: _riderOffset,
                      shopPosition: _shopOffset,
                      showRoute: _isAccepted,
                      animationProgress: _mapAnimController.value,
                    ),
                  );
                },
              );
            },
          ),

          // 2. LIVE PINS & RADAR PULSING
          Positioned(
            left: _riderOffset.dx - 30,
            top: _riderOffset.dy - 60,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
                  ),
                  child: const Text(
                    'YOU',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulse ring
                    AnimatedBuilder(
                      animation: _mapAnimController,
                      builder: (context, _) {
                        return Container(
                          width: 32 + (24 * _mapAnimController.value),
                          height: 32 + (24 * _mapAnimController.value),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.3 * (1.0 - _mapAnimController.value)),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                    const Icon(Icons.navigation_rounded, color: _primaryColor, size: 28),
                  ],
                ),
              ],
            ),
          ),

          if (_hasIncomingRequest || _isAccepted)
            Positioned(
              left: _shopOffset.dx - 30,
              top: _shopOffset.dy - 60,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
                    ),
                    child: const Text(
                      'STORE',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.storefront_rounded, color: Colors.redAccent, size: 28),
                ],
              ),
            ),

          // 3. INCOMING REQUEST CARD (BOTTOM OVERLAY)
          if (_hasIncomingRequest && !_isAccepted)
            _buildIncomingRequestCard(),

          // Offline hint message overlay
          if (!_isOnline)
            Container(
              color: Colors.white.withOpacity(0.92),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.wifi_off_rounded,
                          size: 56,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "You're currently Offline",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Toggle "Online" in the top bar or click the button below to start receiving incoming grocery delivery jobs.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.45),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: 200,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => _toggleOnlineStatus(true),
                          icon: const Icon(Icons.wifi_rounded, size: 18),
                          label: const Text('Go Online Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 2,
                            shadowColor: _primaryColor.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── TAB 2: EARNINGS & RUNS ─────────────────────────────────────────────────
  Widget _buildEarningsTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Earnings', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Earnings Summary Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryColor, Color(0xFF115E59)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.35),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL EARNINGS TODAY', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  const Text(
                    'Rs. 4,850',
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryItem('Completed Runs', '12', Icons.check_circle_rounded),
                      _buildSummaryItem('Accept Rate', '98%', Icons.thumb_up_rounded),
                      _buildSummaryItem('Hours Online', '8.5h', Icons.timer_rounded),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Completed Runs Header
            const Text(
              'Completed Runs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),

            // Completed Runs List
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildCompletedRunItem('GFG-1025', 'Al-Fatah Premium Store', 'Model Town Block B', 180, 'Just Now'),
                _buildCompletedRunItem('GFG-1018', 'Metro Cash & Carry', 'Johar Town Block H', 220, '2 hrs ago'),
                _buildCompletedRunItem('GFG-1011', 'Go Fast Grocery WH', 'DHA Phase 5 Block K', 150, '5 hrs ago'),
                _buildCompletedRunItem('GFG-1002', 'Al-Fatah Premium Store', 'Faisal Town Block C', 190, 'Yesterday'),
                _buildCompletedRunItem('GFG-0994', 'Green Valley Mart', 'Bahria Town Sector C', 240, 'Yesterday'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String val, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white60, fontSize: 9)),
            Text(val, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletedRunItem(String id, String shop, String dropArea, double earning, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 5, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0FDF4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delivery_dining_rounded, color: Color(0xFF10B981), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Run #$id', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                      const SizedBox(height: 2),
                      Text(
                        '$shop → $dropArea',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rs. ${earning.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, color: _primaryColor, fontSize: 14)),
              const SizedBox(height: 2),
              Text(time, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── TAB 3: RIDER PROFILE ───────────────────────────────────────────────────
  Widget _buildProfileTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // User identity section
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: _primaryColor.withOpacity(0.1),
                  child: const Icon(Icons.delivery_dining_rounded, size: 40, color: _primaryColor),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demo Rider',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF0F172A)),
                      ),
                      SizedBox(height: 4),
                      Text('rider@foodexpress.com', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      SizedBox(height: 2),
                      Text('+92 300 0987654', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Status Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Verification Status: ACTIVE & VERIFIED',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15803D), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profile info grid
            _buildProfileSectionHeader('Documents & Verification'),
            _buildProfileInfoItem('CNIC Number', '35201-1234567-9', Icons.credit_card_rounded),
            _buildProfileInfoItem('Driving License', 'DL-LH-882910', Icons.badge_rounded),
            
            const SizedBox(height: 16),
            _buildProfileSectionHeader('Vehicle Information'),
            _buildProfileInfoItem('Vehicle Type', 'Heavy Motorbike', Icons.motorcycle_rounded),
            _buildProfileInfoItem('License Plate', 'LH-8812', Icons.crop_16_9_rounded),

            const SizedBox(height: 16),
            _buildProfileSectionHeader('Payout Settings'),
            _buildProfileInfoItem('Payout Method', 'Bank Transfer', Icons.account_balance_rounded),
            _buildProfileInfoItem('Account Number', 'PK24AAAA000011223344', Icons.password_rounded),

            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<PhoneAuthBloc>().add(LogoutEvent());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF2F2),
                  foregroundColor: Colors.red.shade700,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.red.shade100),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Log Out of Rider Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
        ),
      ),
    );
  }

  Widget _buildProfileInfoItem(String key, String val, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(key, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                Text(val, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Ringing Visually Loud Card
  Widget _buildIncomingRequestCard() {
    final isOverLimit = _codAmount > _riderCodLimit;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 20,
      child: ScaleTransition(
        scale: _ringScaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
            border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header indicator
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    AnimatedBuilder(
                      animation: _ringOpacityAnimation,
                      builder: (context, _) {
                        return Opacity(
                          opacity: _ringOpacityAnimation.value,
                          child: const Text(
                            'INCOMING JOBS AVAILABLE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 1.0,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ID + Earnings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order #$_incomingOrderId',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1F2937)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Earn Rs. ${_estimatedEarning.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF047857), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFF3F4F6)),

                    // Pickup Location (Shop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                          child: const Icon(Icons.storefront_rounded, size: 10, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PICKUP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                              Text(
                                _shopName,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1F2937)),
                              ),
                              Text(_shopArea, style: const TextStyle(fontSize: 12, color: Colors.black45)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Drop-off Location (Customer Area)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(color: _primaryColor, shape: BoxShape.circle),
                          child: const Icon(Icons.person_pin_circle_rounded, size: 10, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DROP-OFF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _primaryColor)),
                              Text(
                                _customerArea,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1F2937)),
                              ),
                              const Text('Exact house address hidden until accept', style: TextStyle(fontSize: 11, color: Colors.black38, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFF3F4F6)),

                    // COD details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cash Collection at Drop-off:', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
                        Text(
                          'Rs. ${_codAmount.toStringAsFixed(0)} (COD)',
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // COD Limit Security check warning alert
                    if (isOverLimit)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'COD LIMIT EXCEEDED (Rs. ${_riderCodLimit.toStringAsFixed(0)} max)',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'This order requires collection of Rs. ${_codAmount.toStringAsFixed(0)}. Admin clearance required before you can accept.',
                                    style: TextStyle(fontSize: 11, color: Colors.red.shade700, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _hasIncomingRequest = false;
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade600,
                              backgroundColor: Colors.grey.shade100,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Pass/Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: isOverLimit
                              ? ElevatedButton.icon(
                                  onPressed: () {
                                    context.read<OrderBloc>().add(
                                      RequestAdminApprovalEvent(
                                        _incomingOrderId,
                                        codAmount: _codAmount,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.security_rounded, size: 16),
                                  label: const Text('Request Admin Approval', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade800,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    elevation: 0,
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: _navigateToActiveDelivery,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    elevation: 0,
                                  ),
                                  child: const Text('Accept Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

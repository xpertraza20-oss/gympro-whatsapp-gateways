import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/services/location_broadcast_service.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> with TickerProviderStateMixin {
  Timer? _pollingTimer;
  Map<String, dynamic>? _cachedOrder;
  String? _errorMessage;
  bool _isLoading = false;

  StreamSubscription? _fbSubscription;
  StreamSubscription? _localSubscription;
  double _riderHeading = 0.0;
  bool _isTrackingLive = false;

  GoogleMapController? _mapController;
  LatLng _riderLatLng = const LatLng(31.4800, 74.3200);
  LatLng _oldRiderLatLng = const LatLng(31.4800, 74.3200);
  LatLng _newRiderLatLng = const LatLng(31.4800, 74.3200);
  AnimationController? _markerAnimController;

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
    _startTracking();

    _markerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _markerAnimController!.addListener(() {
      final t = _markerAnimController!.value;
      final lat = (_newRiderLatLng.latitude - _oldRiderLatLng.latitude) * t + _oldRiderLatLng.latitude;
      final lng = (_newRiderLatLng.longitude - _oldRiderLatLng.longitude) * t + _oldRiderLatLng.longitude;
      if (!mounted) return;
      setState(() {
        _riderLatLng = LatLng(lat, lng);
      });
      
      // Move camera to follow rider
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _riderLatLng,
            zoom: 15.5,
            bearing: _riderHeading,
          ),
        ),
      );
    });

    // Setup polling every 8 seconds to sync status from server silently
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      _fetchStatus();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _fbSubscription?.cancel();
    _localSubscription?.cancel();
    _markerAnimController?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _startTracking() {
    final orderIdStr = widget.orderId.toString();

    // 1. Listen to Local Stream fallback for single-device simulator testing
    _localSubscription = LocationBroadcastService().onLocalLocationChanged.listen((coords) {
      final double lat = coords['latitude'] ?? _riderLatLng.latitude;
      final double lng = coords['longitude'] ?? _riderLatLng.longitude;
      final double heading = coords['heading'] ?? _riderHeading;
      _onLocationReceived(lat, lng, heading);
    });

    // 2. Listen to Firebase Realtime Database
    try {
      _fbSubscription = FirebaseDatabase.instance
          .ref('active_deliveries/$orderIdStr/rider_location')
          .onValue
          .listen((event) {
        final data = event.snapshot.value as Map?;
        if (data != null) {
          final double lat = (data['latitude'] as num?)?.toDouble() ?? _riderLatLng.latitude;
          final double lng = (data['longitude'] as num?)?.toDouble() ?? _riderLatLng.longitude;
          final double heading = (data['heading'] as num?)?.toDouble() ?? _riderHeading;
          _onLocationReceived(lat, lng, heading);
        }
      }, onError: (e) {
        debugPrint("OrderTrackingScreen: Firebase subscription error: $e");
      });
    } catch (e) {
      debugPrint("OrderTrackingScreen: Firebase connection error: $e");
    }
  }

  void _onLocationReceived(double lat, double lng, double heading) {
    if (!mounted) return;
    setState(() {
      _riderHeading = heading;
      _isTrackingLive = true;
      _oldRiderLatLng = _riderLatLng;
      _newRiderLatLng = LatLng(lat, lng);
    });
    _markerAnimController?.forward(from: 0.0);
  }

  Set<Marker> _getMarkers(double shopLat, double shopLng, double customerLat, double customerLng) {
    return {
      Marker(
        markerId: const MarkerId('shop'),
        position: LatLng(shopLat, shopLng),
        infoWindow: const InfoWindow(title: 'Al-Fatah Store (Pickup)'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
      Marker(
        markerId: const MarkerId('customer'),
        position: LatLng(customerLat, customerLng),
        infoWindow: const InfoWindow(title: 'Your Address (Drop-off)'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('rider'),
        position: _riderLatLng,
        rotation: _riderHeading,
        flat: true,
        infoWindow: const InfoWindow(title: 'Delivery Rider'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };
  }

  Set<Polyline> _getPolylines(double shopLat, double shopLng, double customerLat, double customerLng) {
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(shopLat, shopLng),
          _riderLatLng,
          LatLng(customerLat, customerLng),
        ],
        color: const Color(0xFF006E2F),
        width: 5,
      ),
    };
  }

  Widget _buildLiveMapSection() {
    // Max distance from shop to customer is approx 0.0108
    const double maxDistance = 0.0108;
    double dx = 31.4890 - _riderLatLng.latitude;
    double dy = 74.3260 - _riderLatLng.longitude;
    double distanceRemaining = math.sqrt(dx * dx + dy * dy);
    double progress = 1.0 - (distanceRemaining / maxDistance).clamp(0.0, 1.0);
    int etaMinutes = ((1.0 - progress) * 12).round() + 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Actual Google Maps Live tracking view
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
             children: [
               GoogleMap(
                 initialCameraPosition: CameraPosition(
                   target: _riderLatLng,
                   zoom: 15.5,
                 ),
                 markers: _getMarkers(31.4800, 74.3200, 31.4890, 74.3260),
                 polylines: _getPolylines(31.4800, 74.3200, 31.4890, 74.3260),
                 onMapCreated: (GoogleMapController controller) {
                   _mapController = controller;
                 },
                 myLocationButtonEnabled: false,
                 zoomControlsEnabled: false,
               ),
               // Pulse live tracking label
               Positioned(
                 top: 12,
                 left: 12,
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                   decoration: BoxDecoration(
                     color: const Color(0xFF006E2F),
                     borderRadius: BorderRadius.circular(20),
                   ),
                   child: const Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Icon(Icons.radar_rounded, color: Colors.white, size: 12),
                       SizedBox(width: 4),
                       Text(
                         'LIVE TRACKING ACTIVE',
                         style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                       ),
                     ],
                   ),
                 ),
               ),
             ],
          ),
        ),
        const SizedBox(height: 16),

        // Rider Info Bottom Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade100.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF006E2F).withOpacity(0.1),
                child: const Icon(Icons.directions_bike_rounded, color: Color(0xFF006E2F), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DELIVERY PARTNER',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF006E2F), letterSpacing: 0.5),
                    ),
                    const Text(
                      'Zeeshan Khan (Demo Rider)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
                    ),
                    Text(
                      'Bike: LE-7788 | Mobile: +92 300 987 6543',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF006E2F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'ETA',
                      style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$etaMinutes Min',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _fetchStatus() {
    context.read<OrderBloc>().add(FetchOrderTrackingEvent(widget.orderId));
  }

  int _getStatusStep(String status) {
    final s = status.toLowerCase();
    if (s == 'pending') return 0;
    if (s == 'accepted' || s == 'preparing' || s == 'ready_for_pickup') return 1;
    if (s == 'rider_assigned' || s == 'picked_up' || s == 'on_the_way' || s == 'dispatched') return 2;
    if (s == 'delivered') return 3;
    return 0;
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
            if (_cachedOrder == null) {
              setState(() {
                _isLoading = true;
              });
            }
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
                    if (currentStatus.toLowerCase() == 'cancelled') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Order Cancelled',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14),
                                ),
                              ],
                            ),
                            if (order['cancel_reason'] != null && order['cancel_reason'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Reason: ${order['cancel_reason']}',
                                style: TextStyle(color: Colors.red.shade900, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 36),
                    if (currentStatus.toLowerCase() == 'dispatched' ||
                        currentStatus.toLowerCase() == 'rider_assigned' ||
                        currentStatus.toLowerCase() == 'picked_up' ||
                        currentStatus.toLowerCase() == 'on_the_way') ...[
                      _buildLiveMapSection(),
                    ],

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
                      Text(
                        _errorMessage!.contains('404') || _errorMessage!.toLowerCase().contains('not found')
                            ? 'No tracking status details available.'
                            : 'Failed to load tracking: $_errorMessage',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                      ),
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


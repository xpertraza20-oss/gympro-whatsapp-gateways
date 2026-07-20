import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../checkout/presentation/bloc/order_bloc.dart';
import '../../../checkout/presentation/bloc/order_event.dart';
import '../../../checkout/presentation/bloc/order_state.dart';
import '../../../checkout/domain/repositories/order_repository.dart';
import '../../../../core/services/location_broadcast_service.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final Map<String, dynamic> deliveryDetails;

  const ActiveDeliveryScreen({super.key, required this.deliveryDetails});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  bool _isTripStarted = false;
  double _sliderProgress = 0.0;
  bool _isLoading = false;

  static const _primaryColor = Color(0xFF0F766E); // Teal
  static const _accentColor = Color(0xFF14B8A6);

  GoogleMapController? _mapController;
  LatLng _riderLatLng = const LatLng(31.4800, 74.3200);
  double _riderHeading = 0.0;
  StreamSubscription? _riderLocationSub;

  @override
  void initState() {
    super.initState();
    // Parse initial coordinates if provided
    final double initialLat = double.tryParse(widget.deliveryDetails['riderLat']?.toString() ?? '') ?? 31.4800;
    final double initialLng = double.tryParse(widget.deliveryDetails['riderLng']?.toString() ?? '') ?? 74.3200;
    _riderLatLng = LatLng(initialLat, initialLng);

    // Listen to local broadcast stream updates
    _riderLocationSub = LocationBroadcastService().onLocalLocationChanged.listen((coords) {
      if (!mounted) return;
      setState(() {
        _riderLatLng = LatLng(coords['latitude'] ?? _riderLatLng.latitude, coords['longitude'] ?? _riderLatLng.longitude);
        _riderHeading = coords['heading'] ?? _riderHeading;
      });
      // Move camera to follow rider
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _riderLatLng,
            zoom: 16.0,
            bearing: _riderHeading,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    final orderId = widget.deliveryDetails['orderId']?.toString() ?? '1029';
    LocationBroadcastService().stopBroadcasting(orderId);
    _riderLocationSub?.cancel();
    _mapController?.dispose();
    super.dispose();
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
        infoWindow: const InfoWindow(title: 'Customer Address (Drop-off)'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('rider'),
        position: _riderLatLng,
        rotation: _riderHeading,
        flat: true,
        infoWindow: const InfoWindow(title: 'Your Location (Bike)'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };
  }

  Set<Polyline> _getPolylines(double shopLat, double shopLng, double customerLat, double customerLng) {
    if (!_isTripStarted) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(shopLat, shopLng),
          _riderLatLng,
          LatLng(customerLat, customerLng),
        ],
        color: const Color(0xFF0F766E),
        width: 5,
      ),
    };
  }

  Future<void> _onSwipeComplete() async {
    final orderIdStr = widget.deliveryDetails['orderId']?.toString() ?? '1029';
    final orderIdInt = int.tryParse(orderIdStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1029;
    
    setState(() {
      _isLoading = true;
    });

    final repo = RepositoryProvider.of<OrderRepository>(context);

    if (!_isTripStarted) {
      try {
        await repo.updateRiderOrderStatus(orderIdInt, 'pickup');
      } catch (e) {
        print("[ActiveDeliveryScreen] Start Trip API failed: $e");
      }
      
      setState(() {
        _isTripStarted = true;
        _sliderProgress = 0.0;
        _isLoading = false;
      });
      LocationBroadcastService().startBroadcasting(orderIdStr);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip started! Route activated.'),
          backgroundColor: _primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      try {
        await repo.updateRiderOrderStatus(orderIdInt, 'deliver');
      } catch (e) {
        print("[ActiveDeliveryScreen] Complete Trip API failed: $e");
      }

      setState(() {
        _isLoading = false;
      });
      LocationBroadcastService().stopBroadcasting(orderIdStr);

      final codAmount = widget.deliveryDetails['codAmount'] ?? 5200.0;
      final earnings = widget.deliveryDetails['earnings'] ?? 180.0;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Job Complete!', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Delivery completed successfully!'),
              const SizedBox(height: 12),
              Text('Cash Collected: Rs. ${codAmount.toStringAsFixed(0)}'),
              Text('Trip Earnings: Rs. ${earnings.toStringAsFixed(0)}'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.deliveryDetails['orderId'] ?? '1029';
    final shopName = widget.deliveryDetails['shopName'] ?? 'Al-Fatah Premium Store';
    final shopArea = widget.deliveryDetails['shopArea'] ?? 'Block D, Model Town, Lahore';
    
    final exactAddress = widget.deliveryDetails['exactAddress'] ?? 'House 142, Block D, Model Town, Lahore';
    final customerPhone = widget.deliveryDetails['customerPhone'] ?? '+92 300 123 4567';
    final customerName = widget.deliveryDetails['customerName'] ?? 'Ahmed Raza';
    final codAmount = widget.deliveryDetails['codAmount'] ?? 5200.0;
    final earnings = widget.deliveryDetails['earnings'] ?? 180.0;

    return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: Text(
            'Active Run #$orderId',
            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1F2937), fontSize: 18),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // 1. ACTUAL GOOGLE MAPS ACTIVE NAVIGATION VIEW
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _riderLatLng,
                      zoom: 16.0,
                    ),
                    markers: _getMarkers(
                      double.tryParse(widget.deliveryDetails['shopLat']?.toString() ?? '') ?? 31.4800,
                      double.tryParse(widget.deliveryDetails['shopLng']?.toString() ?? '') ?? 74.3200,
                      double.tryParse(widget.deliveryDetails['customerLat']?.toString() ?? '') ?? 31.4890,
                      double.tryParse(widget.deliveryDetails['customerLng']?.toString() ?? '') ?? 74.3260,
                    ),
                    polylines: _getPolylines(
                      double.tryParse(widget.deliveryDetails['shopLat']?.toString() ?? '') ?? 31.4800,
                      double.tryParse(widget.deliveryDetails['shopLng']?.toString() ?? '') ?? 74.3200,
                      double.tryParse(widget.deliveryDetails['customerLat']?.toString() ?? '') ?? 31.4890,
                      double.tryParse(widget.deliveryDetails['customerLng']?.toString() ?? '') ?? 74.3260,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                  // Status Badge overlay
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isTripStarted ? Colors.amber.shade700 : _primaryColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
                      ),
                      child: Text(
                        _isTripStarted ? 'TRIP IN PROGRESS' : 'EN ROUTE TO SHOP',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  // Pulsing Live Location active badge
                  if (_isTripStarted)
                    const Positioned(
                      top: 52,
                      right: 16,
                      child: _PulsingLiveBadge(),
                    ),
                ],
              ),
            ),

            // 2. ACTIVE DELIVERY DETAILS PANEL
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Name & Contact details (Phone + Call Button)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DELIVER TO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                            Text(
                              customerName,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1F2937)),
                            ),
                          ],
                        ),
                        // Call action button
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text('Simulate Call', style: TextStyle(fontWeight: FontWeight.bold)),
                                content: Text('Calling customer $customerName at $customerPhone...'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('End Call', style: TextStyle(color: Colors.redAccent))),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.call_rounded, size: 16),
                          label: const Text('Call', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                            foregroundColor: Colors.green.shade700,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFF3F4F6)),

                    // Locations flow: Pickup to Drop-off
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // Pickup details
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.storefront_rounded, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('PICKUP FROM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                    Text(shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151))),
                                    Text(shopArea, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Drop-off exact address (previously hidden)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_rounded, color: _primaryColor, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('EXACT DROP-OFF ADDRESS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _primaryColor)),
                                    Text(exactAddress, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151))),
                                    Text('Tel: $customerPhone', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 20, color: Color(0xFFF3F4F6)),

                    // COD Collection & Earnings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CASH TO COLLECT', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text(
                              'Rs. ${codAmount.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.redAccent),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('YOUR EARNINGS', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text(
                              'Rs. ${earnings.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Swipe Slider Widget
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: _primaryColor))
                        : Container(
                            height: 56,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final maxSlide = constraints.maxWidth - 56;
                                return Stack(
                                  children: [
                                    // Slide instructions
                                    Center(
                                      child: Text(
                                        _isTripStarted ? 'Swipe to Mark as Delivered >>' : 'Swipe to Start Trip >>',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: _isTripStarted ? Colors.amber.shade800 : _primaryColor,
                                        ),
                                      ),
                                    ),
                                    // Slide handle
                                    Positioned(
                                      left: _sliderProgress * maxSlide,
                                      child: GestureDetector(
                                        onHorizontalDragUpdate: (details) {
                                          setState(() {
                                            _sliderProgress += details.primaryDelta! / maxSlide;
                                            if (_sliderProgress < 0.0) _sliderProgress = 0.0;
                                            if (_sliderProgress > 1.0) _sliderProgress = 1.0;
                                          });
                                        },
                                        onHorizontalDragEnd: (details) {
                                          if (_sliderProgress > 0.8) {
                                            setState(() {
                                              _sliderProgress = 1.0;
                                            });
                                            _onSwipeComplete();
                                          } else {
                                            setState(() {
                                              _sliderProgress = 0.0;
                                            });
                                          }
                                        },
                                        child: Container(
                                          width: 56,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            color: _isTripStarted ? Colors.amber.shade700 : _primaryColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.15),
                                                blurRadius: 6,
                                                offset: const Offset(2, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingLiveBadge extends StatefulWidget {
  const _PulsingLiveBadge();

  @override
  State<_PulsingLiveBadge> createState() => _PulsingLiveBadgeState();
}

class _PulsingLiveBadgeState extends State<_PulsingLiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        return Opacity(
          opacity: 0.4 + _pulseCtrl.value * 0.6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.4),
                  blurRadius: 6,
                  spreadRadius: 2,
                )
              ]
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.white, size: 8),
                SizedBox(width: 6),
                Text(
                  'Live Location Active',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationBroadcastService {
  static final LocationBroadcastService _instance = LocationBroadcastService._internal();
  factory LocationBroadcastService() => _instance;
  LocationBroadcastService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _mockTimer;

  // Broadcaster controller to allow local screens to listen to the location stream directly
  // This is a great fallback for local testing on a single device/emulator!
  final StreamController<Map<String, double>> _localLocationController = 
      StreamController<Map<String, double>>.broadcast();

  Stream<Map<String, double>> get onLocalLocationChanged => _localLocationController.stream;

  Future<bool> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return false;
      }
      return true;
    } catch (e) {
      debugPrint("Error requesting location permission: $e");
      return false;
    }
  }

  void startBroadcasting(String orderId) async {
    debugPrint("LocationBroadcastService: Starting broadcast for order $orderId");
    final hasPermission = await requestPermission();

    // Clean up existing streams first
    stopBroadcasting(orderId);

    if (hasPermission) {
      try {
        const locationSettings = LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2, // Update every 2 meters
        );

        _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _updateCoordinates(orderId, position.latitude, position.longitude, position.heading);
          },
          onError: (e) {
            debugPrint("Location stream error, starting simulated fallback: $e");
            _startMockBroadcast(orderId);
          },
        );
      } catch (e) {
        debugPrint("Failed to start Geolocator stream, starting simulated fallback: $e");
        _startMockBroadcast(orderId);
      }
    } else {
      debugPrint("Location permission denied. Starting simulated fallback.");
      _startMockBroadcast(orderId);
    }
  }

  void _updateCoordinates(String orderId, double lat, double lng, double heading) {
    // 1. Broadcast locally for single-device simulation tracking
    _localLocationController.add({
      'latitude': lat,
      'longitude': lng,
      'heading': heading,
    });

    // 2. Push to Firebase Realtime Database
    try {
      final dbRef = FirebaseDatabase.instance.ref();
      dbRef.child('active_deliveries/$orderId/rider_location').set({
        'latitude': lat,
        'longitude': lng,
        'heading': heading,
        'timestamp': ServerValue.timestamp,
      });
      debugPrint("LocationBroadcastService: Updated location in Firebase Realtime Database for order $orderId ($lat, $lng)");
    } catch (e) {
      debugPrint("Firebase Realtime Database error: $e. Location broadcasted locally only.");
    }
  }

  void _startMockBroadcast(String orderId) {
    // Simulate rider movement from Model Town block D (near shop) to a customer house
    // Let's define a path of Lat/Lngs
    final List<Map<String, double>> path = [
      {'latitude': 31.4800, 'longitude': 74.3200, 'heading': 90.0},
      {'latitude': 31.4810, 'longitude': 74.3210, 'heading': 90.0},
      {'latitude': 31.4820, 'longitude': 74.3220, 'heading': 45.0},
      {'latitude': 31.4830, 'longitude': 74.3230, 'heading': 45.0},
      {'latitude': 31.4840, 'longitude': 74.3235, 'heading': 0.0},
      {'latitude': 31.4850, 'longitude': 74.3240, 'heading': 0.0},
      {'latitude': 31.4860, 'longitude': 74.3245, 'heading': 30.0},
      {'latitude': 31.4870, 'longitude': 74.3250, 'heading': 30.0},
      {'latitude': 31.4880, 'longitude': 74.3255, 'heading': 60.0},
      {'latitude': 31.4890, 'longitude': 74.3260, 'heading': 90.0},
    ];

    int step = 0;
    _mockTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (step >= path.length) {
        step = 0;
      }
      final coords = path[step];
      _updateCoordinates(orderId, coords['latitude']!, coords['longitude']!, coords['heading']!);
      step++;
    });
  }

  void stopBroadcasting(String orderId) {
    debugPrint("LocationBroadcastService: Stopping broadcast for order $orderId");
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    
    _mockTimer?.cancel();
    _mockTimer = null;

    try {
      final dbRef = FirebaseDatabase.instance.ref();
      dbRef.child('active_deliveries/$orderId').remove();
    } catch (e) {
      debugPrint("Firebase Realtime Database clean-up error: $e");
    }
  }
}

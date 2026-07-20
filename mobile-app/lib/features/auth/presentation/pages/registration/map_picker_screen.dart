import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng _selectedLatLng = const LatLng(31.5204, 74.3587); // Default Lahore coordinates
  bool _useGoogleMaps = false; // Fallback to interactive premium mock map for instant testability
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF006E2F);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0.5,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(_selectedLatLng);
            },
            child: const Text(
              'DONE',
              style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 16),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // Dynamic Map View
          _useGoogleMaps
              ? GoogleMap(
                  initialCameraPosition: CameraPosition(target: _selectedLatLng, zoom: 14),
                  onMapCreated: (ctrl) => _mapController = ctrl,
                  onCameraMove: (pos) {
                    setState(() {
                      _selectedLatLng = pos.target;
                    });
                  },
                )
              : _buildPremiumInteractiveMockMap(),

          // Centered Pin Crosshair Overlay
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)
                    ]
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.redAccent,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Location details panel
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location_rounded, color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Dropped Pin Coordinates',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                      ),
                      const Spacer(),
                      // Switch Map Type
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _useGoogleMaps = !_useGoogleMaps;
                          });
                        },
                        child: Text(
                          _useGoogleMaps ? 'Use Visual Grid' : 'Use Google Maps',
                          style: const TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Latitude: ${_selectedLatLng.latitude.toStringAsFixed(6)}\nLongitude: ${_selectedLatLng.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(_selectedLatLng);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Confirm Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // A highly-designed interactive mock map selector for instant testability
  Widget _buildPremiumInteractiveMockMap() {
    return GestureDetector(
      onPanUpdate: (details) {
        // Adjust coordinates dynamically as user drags the grid
        setState(() {
          double latDelta = -details.delta.dy * 0.0001;
          double lngDelta = details.delta.dx * 0.0001;
          _selectedLatLng = LatLng(
            _selectedLatLng.latitude + latDelta,
            _selectedLatLng.longitude + lngDelta,
          );
        });
      },
      child: Container(
        color: const Color(0xFFE2E8F0),
        child: Stack(
          children: [
            // Draw simulated map grid lines and locations
            Positioned.fill(
              child: CustomPaint(
                painter: _MapGridPainter(),
              ),
            ),
            // Simulated landmarks or texts in background
            const Positioned(
              top: 150,
              left: 100,
              child: Opacity(
                opacity: 0.3,
                child: Text('Main Commercial Area', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              ),
            ),
            const Positioned(
              bottom: 200,
              right: 120,
              child: Opacity(
                opacity: 0.3,
                child: Text('Residential Block C', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              ),
            ),
            // Tap indicator helper
            const Positioned(
              top: 80,
              left: 24,
              right: 24,
              child: Card(
                color: Colors.white,
                elevation: 1,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: Colors.blueGrey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Drag the map view or drop the pin precisely to fetch the coordinates.',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.0;

    const double step = 40.0;
    
    // Draw vertical lines
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

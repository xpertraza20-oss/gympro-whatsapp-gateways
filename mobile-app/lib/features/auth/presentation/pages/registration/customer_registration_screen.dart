import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../bloc/registration_bloc.dart';
import 'map_picker_screen.dart';

class CustomerRegistrationScreen extends StatefulWidget {
  const CustomerRegistrationScreen({super.key});

  @override
  State<CustomerRegistrationScreen> createState() => _CustomerRegistrationScreenState();
}

class _CustomerRegistrationScreenState extends State<CustomerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  
  double? _lat;
  double? _lng;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final phoneArg = ModalRoute.of(context)?.settings.arguments as String?;
    if (phoneArg != null && _phoneCtrl.text.isEmpty) {
      _phoneCtrl.text = phoneArg;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _areaCtrl.dispose();
    _streetCtrl.dispose();
    _landmarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final LatLng? picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );
    if (picked != null) {
      setState(() {
        _lat = picked.latitude;
        _lng = picked.longitude;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select your location on the map'),
        backgroundColor: Colors.orangeAccent,
      ));
      return;
    }

    final combinedAddress =
        "${_streetCtrl.text.trim()}, ${_areaCtrl.text.trim()}, ${_cityCtrl.text.trim()} (Landmark: ${_landmarkCtrl.text.trim()})";

    context.read<RegistrationBloc>().add(SubmitCustomerRegistrationEvent(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          addressDetails: combinedAddress,
          lat: _lat!,
          lng: _lng!,
        ));
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B4BF4);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('Complete Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0.5,
      ),
      body: BlocListener<RegistrationBloc, RegistrationState>(
        listener: (context, state) {
          if (state is RegistrationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: primaryColor,
            ));
            Navigator.of(context).pushNamedAndRemoveUntil(state.redirectRoute, (_) => false);
          } else if (state is RegistrationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.error),
              backgroundColor: const Color(0xFFEF4444),
            ));
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Almost there!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please fill in your delivery details to complete your registration.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 28),

                  // Full Name
                  const Text(
                    'Full Name',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'John Doe',
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter name' : null,
                  ),
                  const SizedBox(height: 20),

                  // Phone Number
                  const Text(
                    'Phone Number',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'e.g. +92 300 XXXXXXX',
                      prefixIcon: const Icon(Icons.phone_outlined, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter phone number' : null,
                  ),
                  const SizedBox(height: 20),

                  // City / Wilaya
                  const Text(
                    'City / Wilaya',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _cityCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Lahore, Alger',
                      prefixIcon: const Icon(Icons.location_city_rounded, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter city' : null,
                  ),
                  const SizedBox(height: 20),

                  // Area
                  const Text(
                    'Area',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _areaCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Gulberg, Hydra',
                      prefixIcon: const Icon(Icons.map_outlined, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter area' : null,
                  ),
                  const SizedBox(height: 20),

                  // Street/House Number
                  const Text(
                    'Street/House Number',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _streetCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Street 4, House 12A',
                      prefixIcon: const Icon(Icons.home_outlined, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter street/house address' : null,
                  ),
                  const SizedBox(height: 20),

                  // Nearby Landmark
                  const Text(
                    'Nearby Landmark',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _landmarkCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Near Metro Station',
                      prefixIcon: const Icon(Icons.landscape_outlined, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter landmark' : null,
                  ),
                  const SizedBox(height: 24),

                  // Map coordinates selection status
                  if (_lat != null && _lng != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Location Selected: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}",
                            style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                  // Button to Pick Location on Map
                  OutlinedButton.icon(
                    onPressed: _pickLocation,
                    icon: const Icon(Icons.pin_drop_rounded, size: 20),
                    label: const Text('Select Exact Location on Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: const BorderSide(color: primaryColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Submit button
                  BlocBuilder<RegistrationBloc, RegistrationState>(
                    builder: (context, state) {
                      final isLoading = state is RegistrationLoading;
                      
                      return ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 1,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Complete Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

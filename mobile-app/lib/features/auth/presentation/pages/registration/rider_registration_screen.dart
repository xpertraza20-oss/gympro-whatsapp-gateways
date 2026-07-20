import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../bloc/registration_bloc.dart';

class RiderRegistrationScreen extends StatefulWidget {
  const RiderRegistrationScreen({super.key});

  @override
  State<RiderRegistrationScreen> createState() => _RiderRegistrationScreenState();
}

class _RiderRegistrationScreenState extends State<RiderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cnicCtrl = TextEditingController();
  final _vehicleNumberCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();

  // Dropdown states
  String? _selectedVehicleType;
  String? _selectedPayoutMethod;

  final List<String> _vehicleTypes = ['Bike', 'Cycle', 'Loader'];
  final List<String> _payoutMethods = ['Bank', 'JazzCash', 'Easypaisa'];

  // Attachments
  File? _cnicFront;
  File? _cnicBack;
  File? _license;
  File? _selfie;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkTempRegistration();
  }

  Future<void> _checkTempRegistration() async {
    const secureStorage = FlutterSecureStorage();
    final tempEmergency = await secureStorage.read(key: 'temp_emergency');
    if (tempEmergency != null && tempEmergency.isNotEmpty) {
      final name = await secureStorage.read(key: 'user_name') ?? '';
      final phone = await secureStorage.read(key: 'user_phone') ?? '';
      final cnic = await secureStorage.read(key: 'temp_cnic') ?? '';
      final vehicleType = await secureStorage.read(key: 'temp_vehicle_type') ?? 'Bike';
      final vehicleNumber = await secureStorage.read(key: 'temp_vehicle_number') ?? '';
      final payout = await secureStorage.read(key: 'temp_payout') ?? '';
      final cnicFront = await secureStorage.read(key: 'temp_rider_cnic_front');
      final cnicBack = await secureStorage.read(key: 'temp_rider_cnic_back');
      final license = await secureStorage.read(key: 'temp_rider_license');
      final selfie = await secureStorage.read(key: 'temp_rider_selfie');

      // Clear temp keys
      await secureStorage.delete(key: 'temp_cnic');
      await secureStorage.delete(key: 'temp_emergency');
      await secureStorage.delete(key: 'temp_vehicle_type');
      await secureStorage.delete(key: 'temp_vehicle_number');
      await secureStorage.delete(key: 'temp_payout');
      await secureStorage.delete(key: 'temp_rider_cnic_front');
      await secureStorage.delete(key: 'temp_rider_cnic_back');
      await secureStorage.delete(key: 'temp_rider_license');
      await secureStorage.delete(key: 'temp_rider_selfie');

      if (mounted) {
        context.read<RegistrationBloc>().add(SubmitRiderRegistrationEvent(
              fullName: name.isNotEmpty ? name : _nameCtrl.text,
              phone: phone.isNotEmpty ? phone : _phoneCtrl.text,
              cnic: cnic,
              currentAddress: phone, // Uses phone or location as address placeholder
              emergencyContact: tempEmergency,
              vehicleType: vehicleType,
              vehicleNumber: vehicleNumber,
              bankDetails: payout,
              cnicFrontPath: cnicFront,
              cnicBackPath: cnicBack,
              licensePath: license,
              selfiePath: selfie,
            ));
      }
    }
  }

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
    _emergencyCtrl.dispose();
    _addressCtrl.dispose();
    _cnicCtrl.dispose();
    _vehicleNumberCtrl.dispose();
    _accountNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {
    // 0: CNIC Front, 1: CNIC Back, 2: License, 3: Selfie
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() {
          if (index == 0) {
            _cnicFront = File(file.path);
          } else if (index == 1) {
            _cnicBack = File(file.path);
          } else if (index == 2) {
            _license = File(file.path);
          } else {
            _selfie = File(file.path);
          }
        });
      }
    } catch (e) {
      debugPrint("Image picking failed: $e");
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedVehicleType == null) {
      _showWarning('Please select a Vehicle Type.');
      return;
    }
    if (_selectedPayoutMethod == null) {
      _showWarning('Please select a Payout Method.');
      return;
    }
    if (_cnicFront == null || _cnicBack == null) {
      _showWarning('Please upload CNIC Front & Back photos.');
      return;
    }
    if (_license == null && _selectedVehicleType != 'Cycle') {
      _showWarning('Please upload a Driving License photo (not required for Cycle).');
      return;
    }
    if (_selfie == null) {
      _showWarning('Please upload a Selfie profile photo.');
      return;
    }

    final payoutCombined = "${_selectedPayoutMethod!} | Account: ${_accountNumberCtrl.text.trim()}";

    context.read<RegistrationBloc>().add(SubmitRiderRegistrationEvent(
          fullName: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          cnic: _cnicCtrl.text.trim(),
          currentAddress: _addressCtrl.text.trim(),
          emergencyContact: _emergencyCtrl.text.trim(),
          vehicleType: _selectedVehicleType!,
          vehicleNumber: _vehicleNumberCtrl.text.trim(),
          bankDetails: payoutCombined,
          cnicFrontPath: _cnicFront?.path,
          cnicBackPath: _cnicBack?.path,
          licensePath: _license?.path,
          selfiePath: _selfie?.path,
        ));
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orangeAccent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF97316); // Orange for Rider portal
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Rider Registration', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    'Join the Fleet',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Complete the form below to apply as a Delivery Partner on Go Fast Grocery.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 28),

                  // ─── SECTION 1: PERSONAL INFO ───
                  const Text('1. PERSONAL INFO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1)),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Full Name
                  const Text('Full Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Full name as per CNIC',
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter full name' : null,
                  ),
                  const SizedBox(height: 16),

                  // Phone Number
                  const Text("Phone Number", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
                  const SizedBox(height: 16),

                  // Emergency Contact
                  const Text('Emergency Contact Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emergencyCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'e.g. +92 300 XXXXXXX',
                      prefixIcon: const Icon(Icons.contact_phone_outlined, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter emergency contact number' : null,
                  ),
                  const SizedBox(height: 16),

                  // Current Address
                  const Text('Current Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _addressCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Enter your residential address...',
                      prefixIcon: const Icon(Icons.home_outlined, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter current address' : null,
                  ),
                  const SizedBox(height: 28),

                  // ─── SECTION 2: IDENTITY DOCUMENTS ───
                  const Text('2. IDENTITY DOCUMENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1)),
                  const Divider(),
                  const SizedBox(height: 12),

                  // CNIC Number
                  const Text('CNIC Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _cnicCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g. 35202-XXXXXXX-X',
                      prefixIcon: const Icon(Icons.badge_outlined, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter CNIC number' : null,
                  ),
                  const SizedBox(height: 16),

                  // CNIC Uploads Side-by-Side
                  Row(
                    children: [
                      Expanded(
                        child: _buildLargeImagePicker(
                          label: 'Upload CNIC Front',
                          file: _cnicFront,
                          onTap: () => _pickImage(0),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildLargeImagePicker(
                          label: 'Upload CNIC Back',
                          file: _cnicBack,
                          onTap: () => _pickImage(1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Upload Selfie
                  _buildLargeImagePicker(
                    label: 'Upload Selfie',
                    file: _selfie,
                    onTap: () => _pickImage(3),
                  ),
                  const SizedBox(height: 28),

                  // ─── SECTION 3: VEHICLE DETAILS ───
                  const Text('3. VEHICLE DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1)),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Vehicle Type
                  const Text('Vehicle Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedVehicleType,
                    items: _vehicleTypes.map((t) {
                      return DropdownMenuItem(value: t, child: Text(t));
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedVehicleType = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Select vehicle type',
                      prefixIcon: const Icon(Icons.directions_bike_rounded, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null ? 'Please select vehicle type' : null,
                  ),
                  const SizedBox(height: 16),

                  // Vehicle Registration Number
                  const Text('Vehicle Registration Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _vehicleNumberCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. LE-12-3456 (or N/A for Cycle)',
                      prefixIcon: const Icon(Icons.credit_card_outlined, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter vehicle registration number' : null,
                  ),
                  const SizedBox(height: 16),

                  // Upload Driving Licence
                  _buildLargeImagePicker(
                    label: 'Upload Driving Licence',
                    file: _license,
                    onTap: () => _pickImage(2),
                  ),
                  const SizedBox(height: 28),

                  // ─── SECTION 4: PAYOUT DETAILS ───
                  const Text('4. PAYOUT DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1)),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Payout Method (Dropdown)
                  const Text("Payout Method", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedPayoutMethod,
                    items: _payoutMethods.map((m) {
                      return DropdownMenuItem(value: m, child: Text(m));
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedPayoutMethod = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Select method',
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null ? 'Please select payout method' : null,
                  ),
                  const SizedBox(height: 16),

                  // Account Number
                  const Text("Account Number", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _accountNumberCtrl,
                    decoration: InputDecoration(
                      hintText: 'Enter Account/JazzCash Number',
                      prefixIcon: const Icon(Icons.payment_rounded, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter account number' : null,
                  ),
                  const SizedBox(height: 36),

                  // ─── SECTION 5: SUBMIT ───
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
                            : const Text('Register & Earn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildLargeImagePicker({
    required String label,
    required File? file,
    required VoidCallback onTap,
  }) {
    const primaryColor = Color(0xFF0F766E);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined, color: primaryColor, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                ],
              ),
      ),
    );
  }
}

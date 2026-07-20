import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../bloc/registration_bloc.dart';
import 'map_picker_screen.dart';

class ShopkeeperRegistrationScreen extends StatefulWidget {
  const ShopkeeperRegistrationScreen({super.key});

  @override
  State<ShopkeeperRegistrationScreen> createState() => _ShopkeeperRegistrationScreenState();
}

class _ShopkeeperRegistrationScreenState extends State<ShopkeeperRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _ownerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cnicCtrl = TextEditingController();
  final _shopNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();

  // Dropdown states
  String? _selectedCategory;
  String? _selectedPayoutMethod;

  final List<String> _categories = ['Grocery', 'Meat', 'Pharmacy', 'Vegetables', 'Bakery', 'Supermarket'];
  final List<String> _payoutMethods = ['Bank', 'JazzCash', 'Easypaisa'];

  // Time details
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;

  // Coordinate details
  double? _lat;
  double? _lng;

  // File attachments
  File? _cnicFront;
  File? _cnicBack;
  File? _shopPhoto;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkTempRegistration();
  }

  Future<void> _checkTempRegistration() async {
    const secureStorage = FlutterSecureStorage();
    final tempShopName = await secureStorage.read(key: 'temp_shop_name');
    if (tempShopName != null && tempShopName.isNotEmpty) {
      final ownerName = await secureStorage.read(key: 'user_name') ?? '';
      final phone = await secureStorage.read(key: 'user_phone') ?? '';
      final cnic = await secureStorage.read(key: 'temp_cnic') ?? '';
      final bankDetails = await secureStorage.read(key: 'temp_payout') ?? '';
      final category = await secureStorage.read(key: 'temp_category') ?? 'Grocery';
      final shopAddress = await secureStorage.read(key: 'temp_shop_address') ?? '';
      final latStr = await secureStorage.read(key: 'temp_lat') ?? '31.5204';
      final lngStr = await secureStorage.read(key: 'temp_lng') ?? '74.3587';
      final cnicFront = await secureStorage.read(key: 'temp_cnic_front');
      final cnicBack = await secureStorage.read(key: 'temp_cnic_back');
      final shopPhoto = await secureStorage.read(key: 'temp_shop_photo');

      // Clear temp keys
      await secureStorage.delete(key: 'temp_cnic');
      await secureStorage.delete(key: 'temp_shop_name');
      await secureStorage.delete(key: 'temp_shop_address');
      await secureStorage.delete(key: 'temp_category');
      await secureStorage.delete(key: 'temp_payout');
      await secureStorage.delete(key: 'temp_lat');
      await secureStorage.delete(key: 'temp_lng');
      await secureStorage.delete(key: 'temp_cnic_front');
      await secureStorage.delete(key: 'temp_cnic_back');
      await secureStorage.delete(key: 'temp_shop_photo');

      if (mounted) {
        context.read<RegistrationBloc>().add(SubmitShopkeeperRegistrationEvent(
              ownerName: ownerName.isNotEmpty ? ownerName : _ownerNameCtrl.text,
              phone: phone.isNotEmpty ? phone : _phoneCtrl.text,
              cnic: cnic,
              bankDetails: bankDetails,
              shopName: tempShopName,
              category: category,
              openingTime: '09:00:00',
              closingTime: '22:00:00',
              shopAddress: shopAddress,
              lat: double.tryParse(latStr) ?? 31.5204,
              lng: double.tryParse(lngStr) ?? 74.3587,
              cnicFrontPath: cnicFront,
              cnicBackPath: cnicBack,
              shopPhotoPath: shopPhoto,
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
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _cnicCtrl.dispose();
    _shopNameCtrl.dispose();
    _addressCtrl.dispose();
    _accountNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isOpening) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
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

  Future<void> _pickImage(int index) async {
    // 0: CNIC Front, 1: CNIC Back, 2: Shop Photo
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() {
          if (index == 0) {
            _cnicFront = File(file.path);
          } else if (index == 1) {
            _cnicBack = File(file.path);
          } else {
            _shopPhoto = File(file.path);
          }
        });
      }
    } catch (e) {
      debugPrint("Image picking failed: $e");
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategory == null) {
      _showWarning('Please select a Business Category.');
      return;
    }
    if (_openingTime == null || _closingTime == null) {
      _showWarning('Please specify opening and closing hours.');
      return;
    }
    if (_lat == null || _lng == null) {
      _showWarning('Please drop a pin on the map to set your location.');
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
    if (_shopPhoto == null) {
      _showWarning('Please upload a Shop photo.');
      return;
    }

    final openingText = "${_openingTime!.hour.toString().padLeft(2, '0')}:${_openingTime!.minute.toString().padLeft(2, '0')}:00";
    final closingText = "${_closingTime!.hour.toString().padLeft(2, '0')}:${_closingTime!.minute.toString().padLeft(2, '0')}:00";
    
    final payoutCombined = "${_selectedPayoutMethod!} | Account: ${_accountNumberCtrl.text.trim()}";

    context.read<RegistrationBloc>().add(SubmitShopkeeperRegistrationEvent(
          ownerName: _ownerNameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          cnic: _cnicCtrl.text.trim(),
          bankDetails: payoutCombined,
          shopName: _shopNameCtrl.text.trim(),
          category: _selectedCategory!,
          openingTime: openingText,
          closingTime: closingText,
          shopAddress: _addressCtrl.text.trim(),
          lat: _lat!,
          lng: _lng!,
          cnicFrontPath: _cnicFront?.path,
          cnicBackPath: _cnicBack?.path,
          shopPhotoPath: _shopPhoto?.path,
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
    const primaryColor = Color(0xFF10B981); // Green for shopkeeper portal
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Store Registration', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    'Merchant Application',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Complete the form below to apply for a merchant account on Go Fast Grocery.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 28),

                  // --- OWNER SECTION ---
                  const Text('1. OWNER INFORMATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1)),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Owner Full Name
                  const Text("Owner's Full Name", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _ownerNameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Full name as per CNIC',
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter owner name' : null,
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

                  // CNIC Number
                  const Text("CNIC / ID Number", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _cnicCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g. 35202-XXXXXXX-X',
                      prefixIcon: const Icon(Icons.assignment_ind_outlined, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter CNIC number' : null,
                  ),
                  const SizedBox(height: 20),

                  // CNIC Front & Back Image Upload buttons with previews
                  const Text("CNIC Document Upload", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCNICPicker(
                          label: 'CNIC Front',
                          file: _cnicFront,
                          onTap: () => _pickImage(0),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCNICPicker(
                          label: 'CNIC Back',
                          file: _cnicBack,
                          onTap: () => _pickImage(1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // --- BUSINESS SECTION ---
                  const Text('2. SHOP & BUSINESS INFO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1)),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Shop Name
                  const Text("Shop Name", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _shopNameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Go Fast Store #1',
                      prefixIcon: const Icon(Icons.storefront_rounded, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter shop name' : null,
                  ),
                  const SizedBox(height: 16),

                  // Business Category (Dropdown)
                  const Text("Business Category", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: _categories.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Select category',
                      prefixIcon: const Icon(Icons.category_outlined, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null ? 'Please select business category' : null,
                  ),
                  const SizedBox(height: 16),

                  // Shop Complete Address
                  const Text("Shop Address", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _addressCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Complete physical street/commercial shop address...',
                      prefixIcon: const Icon(Icons.pin_drop_outlined, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter shop address' : null,
                  ),
                  const SizedBox(height: 16),

                  // Drop Pin on Map Status
                  if (_lat != null && _lng != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Pin Dropped: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}",
                            style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                  // Drop Pin on Map Button
                  OutlinedButton.icon(
                    onPressed: _pickLocation,
                    icon: const Icon(Icons.pin_drop_rounded, size: 20),
                    label: const Text('Drop Pin on Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: const BorderSide(color: primaryColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Shop Display Photo upload & preview
                  const Text("Shop Photo", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  _buildShopPhotoPicker(),
                  const SizedBox(height: 20),

                  // Opening & Closing Hours
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Opening Time", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _selectTime(true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.black38),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 18, color: primaryColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      _openingTime != null ? _openingTime!.format(context) : 'Select',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Closing Time", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _selectTime(false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.black38),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time_filled_rounded, size: 18, color: primaryColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      _closingTime != null ? _closingTime!.format(context) : 'Select',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // --- PAYOUT SECTION ---
                  const Text('3. PAYOUT METHOD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1)),
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

                  // Payout Account Number / IBAN
                  const Text("Account / IBAN Number", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
                            : const Text('Submit Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildCNICPicker({
    required String label,
    required File? file,
    required VoidCallback onTap,
  }) {
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
                  const Icon(Icons.add_a_photo_outlined, color: Colors.black38, size: 28),
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

  Widget _buildShopPhotoPicker() {
    return GestureDetector(
      onTap: () => _pickImage(2),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: _shopPhoto != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.file(
                  _shopPhoto!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront_outlined, color: Colors.black38, size: 36),
                  SizedBox(height: 8),
                  Text(
                    'Upload Shop Display Photo',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                ],
              ),
      ),
    );
  }
}

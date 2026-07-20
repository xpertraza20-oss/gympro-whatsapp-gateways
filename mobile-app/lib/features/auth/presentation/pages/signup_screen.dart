import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../bloc/phone_auth_bloc.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';
import 'welcome_screen.dart';
import 'role_selection_screen.dart';
import 'registration/map_picker_screen.dart';

class SignupScreen extends StatefulWidget {
  final String role;
  const SignupScreen({super.key, this.role = 'customer'});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // Shopkeeper Fields
  final _cnicCtrl = TextEditingController();
  final _shopNameCtrl = TextEditingController();
  final _shopAddressCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedPayoutMethod;
  double? _lat;
  double? _lng;
  File? _cnicFront;
  File? _cnicBack;
  File? _shopPhoto;

  // Rider Fields
  final _emergencyCtrl = TextEditingController();
  final _vehicleNumberCtrl = TextEditingController();
  
  String? _selectedRiderVehicleType;
  String? _selectedRiderPayoutMethod;
  File? _riderCnicFront;
  File? _riderCnicBack;
  File? _riderLicense;
  File? _riderSelfie;
  
  final ImagePicker _picker = ImagePicker();
  final List<String> _categories = ['Grocery', 'Meat', 'Pharmacy', 'Vegetables', 'Bakery', 'Supermarket'];
  final List<String> _payoutMethods = ['Bank', 'JazzCash', 'Easypaisa'];
  final List<String> _vehicleTypes = ['Bike', 'Cycle', 'Loader'];
  
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _obscurePass = true;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locCtrl.dispose();
    _passCtrl.dispose();
    _cnicCtrl.dispose();
    _shopNameCtrl.dispose();
    _shopAddressCtrl.dispose();
    _accountNumberCtrl.dispose();
    _emergencyCtrl.dispose();
    _vehicleNumberCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    const secureStorage = FlutterSecureStorage();

    if (widget.role == 'shopkeeper') {
      if (_selectedCategory == null) {
        _showWarning('Please select a Business Category.');
        return;
      }
      if (_lat == null || _lng == null) {
        _showWarning('Please drop a pin on the map to set shop location.');
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

      // Save all shopkeeper details in local secure storage temporarily
      await secureStorage.write(key: 'temp_cnic', value: _cnicCtrl.text.trim());
      await secureStorage.write(key: 'temp_shop_name', value: _shopNameCtrl.text.trim());
      await secureStorage.write(key: 'temp_shop_address', value: _shopAddressCtrl.text.trim());
      await secureStorage.write(key: 'temp_category', value: _selectedCategory!);
      await secureStorage.write(key: 'temp_payout', value: "${_selectedPayoutMethod!} | Account: ${_accountNumberCtrl.text.trim()}");
      await secureStorage.write(key: 'temp_lat', value: _lat!.toString());
      await secureStorage.write(key: 'temp_lng', value: _lng!.toString());
      await secureStorage.write(key: 'temp_cnic_front', value: _cnicFront!.path);
      await secureStorage.write(key: 'temp_cnic_back', value: _cnicBack!.path);
      await secureStorage.write(key: 'temp_shop_photo', value: _shopPhoto!.path);
    }

    if (widget.role == 'rider') {
      if (_selectedRiderVehicleType == null) {
        _showWarning('Please select a Vehicle Type.');
        return;
      }
      if (_selectedRiderPayoutMethod == null) {
        _showWarning('Please select a Payout Method.');
        return;
      }
      if (_riderCnicFront == null || _riderCnicBack == null) {
        _showWarning('Please upload CNIC Front & Back photos.');
        return;
      }
      if (_riderLicense == null && _selectedRiderVehicleType != 'Cycle') {
        _showWarning('Please upload a Driving License photo.');
        return;
      }
      if (_riderSelfie == null) {
        _showWarning('Please upload a Selfie profile photo.');
        return;
      }

      // Save all rider details in local secure storage temporarily
      await secureStorage.write(key: 'temp_cnic', value: _cnicCtrl.text.trim());
      await secureStorage.write(key: 'temp_emergency', value: _emergencyCtrl.text.trim());
      await secureStorage.write(key: 'temp_vehicle_type', value: _selectedRiderVehicleType!);
      await secureStorage.write(key: 'temp_vehicle_number', value: _vehicleNumberCtrl.text.trim());
      await secureStorage.write(key: 'temp_payout', value: "${_selectedRiderPayoutMethod!} | Account: ${_accountNumberCtrl.text.trim()}");
      await secureStorage.write(key: 'temp_rider_cnic_front', value: _riderCnicFront!.path);
      await secureStorage.write(key: 'temp_rider_cnic_back', value: _riderCnicBack!.path);
      if (_riderLicense != null) await secureStorage.write(key: 'temp_rider_license', value: _riderLicense!.path);
      await secureStorage.write(key: 'temp_rider_selfie', value: _riderSelfie!.path);
    }

    FocusScope.of(context).unfocus();
    context.read<PhoneAuthBloc>().add(SignupEvent(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      location: _locCtrl.text.trim(),
      password: _passCtrl.text,
      role: widget.role,
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
    return BlocConsumer<PhoneAuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthAuthenticated) {
          final role = state.role;
          final status = state.profileStatus;
          if (status == 'incomplete') {
            if (role == 'shopkeeper') {
              Navigator.of(ctx).pushNamedAndRemoveUntil('/shopkeeper_register', (_) => false);
            } else if (role == 'rider') {
              Navigator.of(ctx).pushNamedAndRemoveUntil('/rider_register', (_) => false);
            } else {
              Navigator.of(ctx).pushNamedAndRemoveUntil('/customer_register', (_) => false);
            }
          } else if (status == 'pending') {
            Navigator.of(ctx).pushNamedAndRemoveUntil('/pending_approval', (_) => false);
          } else {
            if (role == 'shopkeeper') {
              Navigator.of(ctx).pushNamedAndRemoveUntil('/shopkeeper_dashboard', (_) => false);
            } else if (role == 'rider') {
              Navigator.of(ctx).pushNamedAndRemoveUntil('/rider_dashboard', (_) => false);
            } else {
              Navigator.of(ctx).pushNamedAndRemoveUntil('/customer_dashboard', (_) => false);
            }
          }
        } else if (state is OtpSentSuccess) {
          Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                verificationId: state.verificationId,
                phoneNumber: state.phoneNumber,
                role: widget.role,
              ),
            ),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    state.message,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }
      },
      builder: (ctx, state) {
        final isLoading = state is AuthLoading;
        
        if (widget.role == 'shopkeeper') {
          return _buildShopkeeperSignup(isLoading);
        } else if (widget.role == 'rider') {
          return _buildRiderSignup(isLoading);
        } else {
          return _buildCustomerSignup(isLoading);
        }
      },
    );
  }

  // ─── CUSTOMER SIGNUP ───────────────────────────────────────────────────────
  Widget _buildCustomerSignup(bool isLoading) {
    const primaryColor = Color(0xFF6B4BF4);
    const primaryContainer = Color(0xFF5B3BE2);
    const onSurfaceVariant = Color(0xFF404944);
    const outlineVariant = Color(0xFFBFC9C3);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FF),
      body: Stack(
        children: [
          // Background Atmospheric Blurs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryContainer.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFED65B).withOpacity(0.06),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Back Button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                            ),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.black.withOpacity(0.06)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Logo Container
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.shopping_basket_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'Go Fast Grocery',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Create Customer Account',
                          style: TextStyle(fontSize: 14, color: onSurfaceVariant),
                        ),
                        const SizedBox(height: 24),

                        // Form card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: outlineVariant.withOpacity(0.4)),
                            boxShadow: [
                              BoxShadow(
                                color: primaryContainer.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [

                                // Full Name
                                const Text("Full Name", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _nameCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'John Doe',
                                    prefixIcon: const Icon(Icons.person_outline_rounded),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter name' : null,
                                ),
                                const SizedBox(height: 12),

                                // Email Input
                                const Text("Email Address", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    hintText: 'name@example.com',
                                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Please enter email';
                                    if (!v.contains('@')) return 'Please enter valid email';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Phone Input
                                const Text("Phone Number", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    hintText: '+1234567890',
                                    prefixIcon: const Icon(Icons.phone_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter phone' : null,
                                ),
                                const SizedBox(height: 12),

                                // Location Input
                                const Text("Delivery City / Wilaya", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _locCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Alger, Oran, etc.',
                                    prefixIcon: const Icon(Icons.location_on_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter location' : null,
                                ),
                                const SizedBox(height: 12),

                                // Password Input
                                const Text("Password", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _passCtrl,
                                  obscureText: _obscurePass,
                                  decoration: InputDecoration(
                                    hintText: 'Choose password',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                    ),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Please enter password';
                                    if (v.length < 6) return 'Password must be 6+ chars';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Submit
                                ElevatedButton(
                                  onPressed: isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryContainer,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text('Register', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageShopkeeper(int index) async {
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

  Future<void> _pickLocationShopkeeper() async {
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

  Future<void> _pickImageRider(int index) async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() {
          if (index == 0) {
            _riderCnicFront = File(file.path);
          } else if (index == 1) {
            _riderCnicBack = File(file.path);
          } else if (index == 2) {
            _riderLicense = File(file.path);
          } else {
            _riderSelfie = File(file.path);
          }
        });
      }
    } catch (e) {
      debugPrint("Image picking failed: $e");
    }
  }

  // ─── SHOPKEEPER SIGNUP ─────────────────────────────────────────────────────
  Widget _buildShopkeeperSignup(bool isLoading) {
    const primaryColor = Color(0xFF10B981);
    const primaryContainer = Color(0xFF059669);
    const onSurfaceVariant = Color(0xFF404944);
    const outlineVariant = Color(0xFFBFC9C3);

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      body: Stack(
        children: [
          // Background Atmospheric Blurs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryContainer.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFED65B).withOpacity(0.08),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Back Button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => RoleSelectionScreen()),
                            ),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.black.withOpacity(0.06)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Logo Header
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.flash_on_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'Go Fast Grocery',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Create Shopkeeper Account',
                          style: TextStyle(fontSize: 14, color: onSurfaceVariant),
                        ),
                        const SizedBox(height: 24),

                        // Form card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: outlineVariant.withOpacity(0.4)),
                            boxShadow: [
                              BoxShadow(
                                color: primaryContainer.withOpacity(0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [

                                // Owner Full Name
                                const Text("Owner's Full Name", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _nameCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Full Name',
                                    prefixIcon: const Icon(Icons.person_outline_rounded),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter owner name' : null,
                                ),
                                const SizedBox(height: 12),

                                // Phone Number
                                const Text("Phone Number", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    hintText: 'Phone Number',
                                    prefixIcon: const Icon(Icons.phone_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter phone number' : null,
                                ),
                                const SizedBox(height: 12),

                                // --- BUSINESS DETAILS ---
                                const Text("Business Details", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(height: 6),

                                // Shop Name
                                TextFormField(
                                  controller: _shopNameCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Shop Name',
                                    prefixIcon: const Icon(Icons.storefront_rounded),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter shop name' : null,
                                ),
                                const SizedBox(height: 12),

                                // CNIC Number
                                TextFormField(
                                  controller: _cnicCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'CNIC Number',
                                    prefixIcon: const Icon(Icons.assignment_ind_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter CNIC number' : null,
                                ),
                                const SizedBox(height: 16),

                                // CNIC Front & Back Document Picker
                                const Text("CNIC Documents", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildCNICUploadTile(
                                        label: 'CNIC Front',
                                        file: _cnicFront,
                                        onTap: () => _pickImageShopkeeper(0),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildCNICUploadTile(
                                        label: 'CNIC Back',
                                        file: _cnicBack,
                                        onTap: () => _pickImageShopkeeper(1),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Business Category Dropdown
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
                                    hintText: 'Business Category',
                                    prefixIcon: const Icon(Icons.category_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => v == null ? 'Please select category' : null,
                                ),
                                const SizedBox(height: 12),

                                // Shop Complete Address
                                TextFormField(
                                  controller: _shopAddressCtrl,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    hintText: 'Shop Complete Address',
                                    prefixIcon: const Icon(Icons.location_on_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter shop address' : null,
                                ),
                                const SizedBox(height: 16),

                                // Drop Pin on Map Status
                                if (_lat != null && _lng != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFFFEDD5)),
                                    ),
                                    child: Text(
                                      "Selected Coordinates: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}",
                                      style: const TextStyle(color: primaryContainer, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),

                                // Drop Pin on Map Button
                                OutlinedButton.icon(
                                  onPressed: _pickLocationShopkeeper,
                                  icon: const Icon(Icons.pin_drop_rounded, size: 18),
                                  label: const Text('Drop Pin on Map for Shop Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primaryColor,
                                    side: const BorderSide(color: primaryColor, width: 1.2),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Shop Photo Image Upload
                                const Text("Shop Display Photo", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                                const SizedBox(height: 6),
                                _buildShopPhotoUploadTile(),
                                const SizedBox(height: 20),

                                // --- PAYOUT METHOD ---
                                const Text("Payout Method", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(height: 8),
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
                                    hintText: 'Payout Method',
                                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => v == null ? 'Please select payout method' : null,
                                ),
                                const SizedBox(height: 12),

                                // Payout Account Number
                                TextFormField(
                                  controller: _accountNumberCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Account Number / JazzCash',
                                    prefixIcon: const Icon(Icons.payment_rounded),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter account number' : null,
                                ),
                                const SizedBox(height: 28),

                                // Submit Button
                                ElevatedButton(
                                  onPressed: isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryContainer,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text('Register & Bolt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCNICUploadTile({required String label, required File? file, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12),
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.file(file, fit: BoxFit.cover, width: double.infinity),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined, color: Colors.black38, size: 22),
                  const SizedBox(height: 6),
                  Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                ],
              ),
      ),
    );
  }

  Widget _buildShopPhotoUploadTile() {
    return GestureDetector(
      onTap: () => _pickImageShopkeeper(2),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12),
        ),
        child: _shopPhoto != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.file(_shopPhoto!, fit: BoxFit.cover, width: double.infinity),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront_outlined, color: Colors.black38, size: 32),
                  SizedBox(height: 6),
                  Text('Upload Shop Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                ],
              ),
      ),
    );
  }

  // ─── RIDER SIGNUP ──────────────────────────────────────────────────────────
  Widget _buildRiderSignup(bool isLoading) {
    const primaryColor = Color(0xFFF97316);
    const primaryContainer = Color(0xFFEA580C);
    const onSurfaceVariant = Color(0xFF404944);
    const outlineVariant = Color(0xFFBFC9C3);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F5),
      body: Stack(
        children: [
          // Background Atmospheric Blurs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFED65B).withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Back Button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                            ),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.black.withOpacity(0.06)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Logo Header
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bike_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'Go Fast Grocery',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Rider Registration Portal',
                          style: TextStyle(fontSize: 14, color: onSurfaceVariant),
                        ),
                        const SizedBox(height: 24),

                        // Form card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: outlineVariant.withOpacity(0.4)),
                            boxShadow: [
                              BoxShadow(
                                color: primaryContainer.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [

                                // ─── SECTION 1: PERSONAL INFO ───
                                const Text('1. PERSONAL INFO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1)),
                                const Divider(),
                                const SizedBox(height: 12),

                                // Full Name
                                const Text("Full Name", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _nameCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Full Name',
                                    prefixIcon: const Icon(Icons.person_outline_rounded),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your name' : null,
                                ),
                                const SizedBox(height: 12),

                                // Email
                                const Text("Email Address", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    hintText: 'name@example.com',
                                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Please enter email';
                                    if (!v.contains('@')) return 'Please enter valid email';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Phone
                                const Text("Phone Number", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    hintText: '+92 300 XXXXXXX',
                                    prefixIcon: const Icon(Icons.phone_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter phone' : null,
                                ),
                                const SizedBox(height: 12),

                                // Emergency Contact
                                const Text("Emergency Contact Number", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _emergencyCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    hintText: '+92 300 XXXXXXX',
                                    prefixIcon: const Icon(Icons.contact_phone_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter emergency contact' : null,
                                ),
                                const SizedBox(height: 12),

                                // Current Address
                                const Text("Current Address", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _locCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Enter your residential address...',
                                    prefixIcon: const Icon(Icons.home_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter current address' : null,
                                ),
                                const SizedBox(height: 12),

                                // Password
                                const Text("Password", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _passCtrl,
                                  obscureText: _obscurePass,
                                  decoration: InputDecoration(
                                    hintText: 'Choose Password',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                    ),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => v == null || v.isEmpty ? 'Please enter password' : null,
                                ),
                                const SizedBox(height: 28),

                                // ─── SECTION 2: IDENTITY DOCUMENTS ───
                                const Text('2. IDENTITY DOCUMENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1)),
                                const Divider(),
                                const SizedBox(height: 12),

                                // CNIC Number
                                const Text("CNIC Number", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _cnicCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 35202-XXXXXXX-X',
                                    prefixIcon: const Icon(Icons.badge_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter CNIC number' : null,
                                ),
                                const SizedBox(height: 16),

                                // CNIC Front & Back Document Picker
                                const Text("CNIC Documents", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildCNICUploadTile(
                                        label: 'CNIC Front',
                                        file: _riderCnicFront,
                                        onTap: () => _pickImageRider(0),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildCNICUploadTile(
                                        label: 'CNIC Back',
                                        file: _riderCnicBack,
                                        onTap: () => _pickImageRider(1),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Upload Selfie
                                const Text("Selfie Photo", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                                const SizedBox(height: 6),
                                _buildCNICUploadTile(
                                  label: 'Upload Selfie',
                                  file: _riderSelfie,
                                  onTap: () => _pickImageRider(3),
                                ),
                                const SizedBox(height: 28),

                                // ─── SECTION 3: VEHICLE DETAILS ───
                                const Text('3. VEHICLE DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1)),
                                const Divider(),
                                const SizedBox(height: 12),

                                // Vehicle Type Dropdown
                                const Text("Vehicle Type", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _selectedRiderVehicleType,
                                  items: _vehicleTypes.map((t) {
                                    return DropdownMenuItem(value: t, child: Text(t));
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedRiderVehicleType = val;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Select vehicle type',
                                    prefixIcon: const Icon(Icons.directions_bike_rounded),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => v == null ? 'Please select vehicle type' : null,
                                ),
                                const SizedBox(height: 12),

                                // Vehicle Registration Number
                                const Text("Vehicle Registration Number", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _vehicleNumberCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. LE-12-3456 (or N/A)',
                                    prefixIcon: const Icon(Icons.credit_card_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter vehicle registration number' : null,
                                ),
                                const SizedBox(height: 16),

                                // Upload Driving Licence
                                const Text("Driving Licence Photo", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                                const SizedBox(height: 6),
                                _buildCNICUploadTile(
                                  label: 'Upload Driving Licence',
                                  file: _riderLicense,
                                  onTap: () => _pickImageRider(2),
                                ),
                                const SizedBox(height: 28),

                                // ─── SECTION 4: PAYOUT DETAILS ───
                                const Text('4. PAYOUT DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1)),
                                const Divider(),
                                const SizedBox(height: 12),

                                // Payout Method (Dropdown)
                                const Text("Payout Method", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _selectedRiderPayoutMethod,
                                  items: _payoutMethods.map((m) {
                                    return DropdownMenuItem(value: m, child: Text(m));
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedRiderPayoutMethod = val;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Select method',
                                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => v == null ? 'Please select payout method' : null,
                                ),
                                const SizedBox(height: 12),

                                // Account Number
                                const Text("Account Number", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _accountNumberCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Enter Account/JazzCash Number',
                                    prefixIcon: const Icon(Icons.payment_rounded),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter account number' : null,
                                ),
                                const SizedBox(height: 36),

                                // Submit
                                ElevatedButton(
                                  onPressed: isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryContainer,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text('Register & Earn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

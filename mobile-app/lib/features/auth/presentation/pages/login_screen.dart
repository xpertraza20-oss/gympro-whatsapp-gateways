import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/phone_auth_bloc.dart';
import 'otp_verification_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, this.role = 'customer'});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  final List<Map<String, String>> _countries = [
    {'code': '+92', 'flag': '🇵🇰', 'name': 'Pakistan'},
    {'code': '+213', 'flag': '🇩🇿', 'name': 'Algeria'},
    {'code': '+966', 'flag': '🇸🇦', 'name': 'Saudi Arabia'},
    {'code': '+971', 'flag': '🇦🇪', 'name': 'UAE'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'USA'},
  ];
  late Map<String, String> _selectedCountry;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _selectedCountry = _countries[0];
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Color _getThemeColor() {
    switch (widget.role) {
      case 'shopkeeper':
        return const Color(0xFF10B981); // Green
      case 'rider':
        return const Color(0xFFF97316); // Orange
      case 'customer':
      default:
        return const Color(0xFF6B4BF4); // Purple
    }
  }

  Color _getLightBgColor() {
    switch (widget.role) {
      case 'shopkeeper':
        return const Color(0xFFECFDF5);
      case 'rider':
        return const Color(0xFFFFF7ED);
      case 'customer':
      default:
        return const Color(0xFFF5F3FF);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    
    final phone = _phoneCtrl.text.trim();
    final password = _passCtrl.text;
    
    final formattedPhone = phone.startsWith('+')
        ? phone
        : '${_selectedCountry['code']}${phone.replaceAll(RegExp(r'^0+'), '')}';

    context.read<PhoneAuthBloc>().add(LoginEvent(
      email: formattedPhone,
      password: password,
      role: widget.role,
    ));
  }

  void _autofillDemo(String phone) {
    setState(() {
      _phoneCtrl.text = phone;
      _passCtrl.text = 'password123';
    });
    Future.delayed(const Duration(milliseconds: 300), _submit);
  }

  Widget _buildPakistanFlag() {
    return Container(
      width: 24,
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            color: Colors.white,
          ),
          Expanded(
            child: Container(
              color: const Color(0xFF01411C),
              child: const Center(
                child: Icon(
                  Icons.star,
                  size: 6,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotsGrid() {
    return SizedBox(
      width: 18,
      height: 18,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2.5,
          mainAxisSpacing: 2.5,
        ),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: _getThemeColor().withOpacity(0.15),
              shape: BoxShape.circle,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getThemeColor();
    final lightBg = _getLightBgColor();

    return BlocConsumer<PhoneAuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is OtpSentSuccess) {
          Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                verificationId: state.verificationId,
                phoneNumber: state.phoneNumber,
                role: widget.role,
              ),
            ),
          );
        } else if (state is AuthAuthenticated) {
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

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FC),
          body: Stack(
            children: [
              // Decorative background shape
              Positioned(
                top: -60,
                left: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeColor.withOpacity(0.05),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Top Navigation Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: const Icon(
                                      Icons.chevron_left_rounded,
                                      color: Color(0xFF1E293B),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                _buildDotsGrid(),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Header Text & Portal Indicator
                            Text(
                              'Phone Login',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Enter your phone number to continue',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: themeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: themeColor.withOpacity(0.15)),
                                ),
                                child: Text(
                                  '${widget.role.toUpperCase()} PORTAL',
                                  style: TextStyle(
                                    color: themeColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Step Indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 24,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 24,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 24,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: themeColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // Main Input Card
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Country Code selector
                                  const Text(
                                    'Country Code',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<Map<String, String>>(
                                        value: _selectedCountry,
                                        icon: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 18,
                                          color: themeColor,
                                        ),
                                        items: _countries.map((Map<String, String> country) {
                                          return DropdownMenuItem<Map<String, String>>(
                                            value: country,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  country['flag']!,
                                                  style: const TextStyle(fontSize: 18),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  country['code']!,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (Map<String, String>? newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              _selectedCountry = newValue;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Phone Number Form field
                                  const Text(
                                    'Phone Number',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: 1.0,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '300 1234567',
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.phone_rounded,
                                        color: themeColor,
                                        size: 20,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: themeColor, width: 2.0),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.redAccent),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
                                      ),
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(11),
                                    ],
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Please enter your phone number';
                                      }
                                      final cleanVal = val.trim();
                                      if (cleanVal.length < 10) {
                                        return 'Phone number must be at least 10 digits';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // Password Form field
                                  const Text(
                                    'Password',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passCtrl,
                                    obscureText: _obscurePass,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: 1.0,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '••••••••',
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_rounded,
                                        color: themeColor,
                                        size: 20,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                          color: Colors.grey.shade400,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePass = !_obscurePass;
                                          });
                                        },
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: themeColor, width: 2.0),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.redAccent),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
                                      ),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (val.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  _TactileGlowButton(
                                    text: 'Log In',
                                    themeColor: themeColor,
                                    isLoading: isLoading,
                                    onTap: _submit,
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SignupScreen(role: widget.role),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 54),
                                      side: BorderSide(color: themeColor.withOpacity(0.4), width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      foregroundColor: themeColor,
                                      backgroundColor: themeColor.withOpacity(0.02),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.person_add_alt_1_rounded, size: 18, color: themeColor),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Create New Account',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: themeColor,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Info Banner Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: lightBg.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: themeColor.withOpacity(0.15)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: lightBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.shield_outlined,
                                      color: themeColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Text(
                                      'We\'ll send a secure OTP verification code to your phone number.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF64748B),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Autofill demo cards section
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey.shade300)),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Text(
                                    'DEMO CREDENTIALS AUTOFILL',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF94A3B8),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey.shade300)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                if (widget.role == 'customer')
                                  Expanded(
                                    child: _buildDemoCard(
                                      roleName: 'Customer',
                                      phone: '3001234567',
                                      icon: Icons.person_rounded,
                                      themeColor: themeColor,
                                      onTap: () => _autofillDemo('3001234567'),
                                    ),
                                  ),
                                if (widget.role == 'shopkeeper')
                                  Expanded(
                                    child: _buildDemoCard(
                                      roleName: 'Shopkeeper',
                                      phone: '3007654321',
                                      icon: Icons.storefront_rounded,
                                      themeColor: themeColor,
                                      onTap: () => _autofillDemo('3007654321'),
                                    ),
                                  ),
                                if (widget.role == 'rider')
                                  Expanded(
                                    child: _buildDemoCard(
                                      roleName: 'Rider',
                                      phone: '3009876543',
                                      icon: Icons.motorcycle_rounded,
                                      themeColor: themeColor,
                                      onTap: () => _autofillDemo('3009876543'),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Footer Trust badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 14, color: themeColor),
                                const SizedBox(width: 6),
                                Text(
                                  'Your number is safe and secure with us.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: themeColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
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
      },
    );
  }

  Widget _buildDemoCard({
    required String roleName,
    required String phone,
    required IconData icon,
    required Color themeColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
          child: Column(
            children: [
              Icon(icon, size: 24, color: themeColor),
              const SizedBox(height: 6),
              Text(
                roleName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                phone,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Auto-Fill',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TactileGlowButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final Color themeColor;
  final bool isLoading;
  final IconData icon;

  const _TactileGlowButton({
    required this.text,
    required this.onTap,
    required this.themeColor,
    required this.isLoading,
    this.icon = Icons.arrow_forward_rounded,
  });

  @override
  State<_TactileGlowButton> createState() => _TactileGlowButtonState();
}

class _TactileGlowButtonState extends State<_TactileGlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 3.0, end: 12.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: widget.themeColor),
      );
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (widget.onTap != null) widget.onTap!();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              height: 56, // Total height including dynamic glow
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.themeColor.withOpacity(0.35),
                    blurRadius: _glowAnimation.value,
                    spreadRadius: _glowAnimation.value / 4,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Container(
            // Parent container represents the dark bottom bevel
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2), // Dark bevel color
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.only(bottom: 4.0), // Bevel depth
            child: Container(
              // Child container represents the premium face of the button
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    widget.themeColor,
                    widget.themeColor.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.text.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 18,
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

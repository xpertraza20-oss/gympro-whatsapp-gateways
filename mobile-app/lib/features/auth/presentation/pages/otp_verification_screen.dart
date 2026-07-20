import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/phone_auth_bloc.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final String role;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.role = 'customer',
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with TickerProviderStateMixin {
  static const _pinLength = 6;
  static const _timerSeconds = 30; // 30 seconds timer as requested

  final List<TextEditingController> _digitCtrl =
      List.generate(_pinLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_pinLength, (_) => FocusNode());
  final List<FocusNode> _keyNodes =
      List.generate(_pinLength, (_) => FocusNode(skipTraversal: true));

  late final AnimationController _fadeCtrl;
  late final AnimationController _liquidCtrl;
  late final Animation<double> _fadeAnim;

  int _secondsLeft = _timerSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _liquidCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _liquidCtrl.dispose();
    _timer?.cancel();
    for (final controller in _digitCtrl) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    for (final node in _keyNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otp => _digitCtrl.map((controller) => controller.text).join();

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _timerSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _verify() {
    if (_otp.length < _pinLength) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter all 6 digits'),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    context.read<PhoneAuthBloc>().add(
          VerifyOtpEvent(
            verificationId: widget.verificationId,
            smsCode: _otp,
            role: widget.role,
            phoneNumber: widget.phoneNumber,
          ),
        );
  }

  void _resend() {
    if (_secondsLeft > 0) return;
    for (final controller in _digitCtrl) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
    context.read<PhoneAuthBloc>().add(
          SendOtpEvent(phoneNumber: widget.phoneNumber, role: widget.role),
        );
    _startTimer();
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == _pinLength && index == 0) {
      for (int i = 0; i < _pinLength; i++) {
        _digitCtrl[i].text = value[i];
      }
      _focusNodes.last.requestFocus();
      return;
    }

    if (value.length == 1 && index < _pinLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _digitCtrl[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _digitCtrl[index - 1].clear();
    }
  }

  String _formatTimerText(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
      listener: (context, state) {
        if (state is OtpVerificationSuccess || state is AuthAuthenticated) {
          final role = state is OtpVerificationSuccess ? state.role : (state as AuthAuthenticated).role;
          final status = state is OtpVerificationSuccess ? state.profileStatus : (state as AuthAuthenticated).profileStatus;

          if (status == 'incomplete') {
            if (role == 'shopkeeper') {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/shopkeeper_register',
                (_) => false,
                arguments: widget.phoneNumber,
              );
            } else if (role == 'rider') {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/rider_register',
                (_) => false,
                arguments: widget.phoneNumber,
              );
            } else {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/customer_register',
                (_) => false,
                arguments: widget.phoneNumber,
              );
            }
          } else if (status == 'pending') {
            Navigator.of(context).pushNamedAndRemoveUntil('/pending_approval', (_) => false);
          } else {
            if (role == 'shopkeeper') {
              Navigator.of(context).pushNamedAndRemoveUntil('/shopkeeper_dashboard', (_) => false);
            } else if (role == 'rider') {
              Navigator.of(context).pushNamedAndRemoveUntil('/rider_dashboard', (_) => false);
            } else {
              Navigator.of(context).pushNamedAndRemoveUntil('/customer_dashboard', (_) => false);
            }
          }
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
          for (final controller in _digitCtrl) {
            controller.clear();
          }
          _focusNodes.first.requestFocus();
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FC),
          body: Stack(
            children: [
              // Decorative background circles
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
              Positioned(
                bottom: -80,
                right: -80,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeColor.withOpacity(0.03),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Nav Bar
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
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(color: const Color(0xFFF1F5F9)),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 16,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Text(
                              'Verification Step 2 of 2'.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: themeColor,
                                letterSpacing: 1.0,
                              ),
                            ),
                            _buildDotsGrid(),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Title Header
                        Text(
                          'Enter OTP Code',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                            height: 1.15,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.04),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'We sent a 6-digit verification code to the number below.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Main Card Container
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Sent to Phone Row with Edit Action
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: lightBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.phone_iphone_rounded,
                                      color: themeColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Sent to',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF94A3B8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '+92 ${widget.phoneNumber}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF0F172A),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Change number back button
                                  IconButton(
                                    icon: const Icon(Icons.edit_note_rounded, size: 22, color: Color(0xFF64748B)),
                                    tooltip: 'Change Phone Number',
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),

                              // OTP input Boxes row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(_pinLength, _buildOtpBox),
                              ),
                              const SizedBox(height: 28),

                              // Tactile Verify Button
                              _TactileGlowButton(
                                text: 'Verify & Continue',
                                themeColor: themeColor,
                                isLoading: isLoading,
                                icon: Icons.check_circle_outline_rounded,
                                onTap: _verify,
                              ),
                              const SizedBox(height: 20),

                              // Auto Verify helper for development testing
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    const demoOtp = '123456';
                                    for (int i = 0; i < _pinLength; i++) {
                                      _digitCtrl[i].text = demoOtp[i];
                                    }
                                    _verify();
                                  },
                                  child: Text(
                                    '⚡ Auto-Verify Demo Code (123456)',
                                    style: TextStyle(
                                      color: themeColor,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Resend Code timer or trigger
                              Center(
                                child: _secondsLeft > 0
                                    ? RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 13,
                                          ),
                                          children: [
                                            const TextSpan(text: 'Resend Code in '),
                                            TextSpan(
                                              text: _formatTimerText(_secondsLeft),
                                              style: TextStyle(
                                                color: themeColor,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : TextButton(
                                        onPressed: _resend,
                                        child: Text(
                                          'Resend Code',
                                          style: TextStyle(
                                            color: themeColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Security Info Card
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
                                  Icons.lock_person_outlined,
                                  color: themeColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Text(
                                  'For your account safety, never share this OTP verification code with anyone.',
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
                        const SizedBox(height: 32),

                        // Bottom trust/security badge matching login screen
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined, size: 14, color: themeColor),
                            const SizedBox(width: 6),
                            const Text(
                              'End-to-End Encrypted Verification',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildOtpBox(int index) {
    final themeColor = _getThemeColor();
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.5),
        child: AnimatedBuilder(
          animation: _focusNodes[index],
          builder: (context, _) {
            final isFocused = _focusNodes[index].hasFocus;
            return AnimatedScale(
              scale: isFocused ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 180),
              child: SizedBox(
                height: 54,
            child: KeyboardListener(
              focusNode: _keyNodes[index],
              onKeyEvent: (event) => _onKeyEvent(index, event),
              child: TextFormField(
                controller: _digitCtrl[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: isFocused ? Colors.white : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isFocused ? themeColor : const Color(0xFFE2E8F0),
                      width: isFocused ? 2 : 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isFocused ? themeColor : const Color(0xFFE2E8F0),
                      width: isFocused ? 2 : 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: themeColor,
                      width: 2.5,
                    ),
                  ),
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(1),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (val) => _onDigitChanged(index, val),
              ),
            ),
          ),
        );
      },
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

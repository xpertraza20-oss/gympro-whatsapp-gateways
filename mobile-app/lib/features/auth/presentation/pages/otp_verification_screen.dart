import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/phone_auth_bloc.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  static const _pinLength = 6;

  // Each digit has its own controller + focus node
  final List<TextEditingController> _digitCtrl =
      List.generate(_pinLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_pinLength, (_) => FocusNode());

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // Countdown timer
  static const int _timerSeconds = 60;
  int _secondsLeft = _timerSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _startTimer();
    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focusNodes[0].requestFocus());
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _timer?.cancel();
    for (final c in _digitCtrl) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _timerSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _otp => _digitCtrl.map((c) => c.text).join();

  void _verify() {
    if (_otp.length < _pinLength) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter all 6 digits'),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    context
        .read<PhoneAuthBloc>()
        .add(VerifyOtpEvent(email: widget.email, otp: _otp));
  }

  void _resend() {
    if (_secondsLeft > 0) return;
    // Clear inputs
    for (final c in _digitCtrl) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    context.read<PhoneAuthBloc>().add(LoginEvent(email: widget.email));
    _startTimer();
  }

  void _onDigitChanged(int index, String val) {
    if (val.length == 1 && index < _pinLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    // Handle paste (all 6 digits pasted into first field)
    if (val.length == _pinLength && index == 0) {
      for (int i = 0; i < _pinLength; i++) {
        _digitCtrl[i].text = val[i];
      }
      _focusNodes[_pinLength - 1].requestFocus();
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PhoneAuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthAuthenticated) {
          // Pop all auth screens and push HomeScreen
          Navigator.of(ctx).pushNamedAndRemoveUntil('/home', (_) => false);
        } else if (state is AuthError) {
          // Shake animation workaround — just show error
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ));
          // Clear OTP boxes on error
          for (final c in _digitCtrl) {
            c.clear();
          }
          _focusNodes[0].requestFocus();
        }
      },
      builder: (ctx, state) {
        final isLoading = state is AuthLoading;
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F2027),
                  Color(0xFF203A43),
                  Color(0xFF2C5364)
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withAlpha(38)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Email icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withAlpha(77),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.mark_email_read_rounded,
                            color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 28),

                      const Text(
                        'Check your email 📬',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: Colors.white.withAlpha(153),
                            fontSize: 14,
                            height: 1.6,
                          ),
                          children: [
                            const TextSpan(
                                text:
                                    'We sent a 6-digit verification code to\n'),
                            TextSpan(
                              text: widget.email,
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // 6-digit PIN boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(_pinLength, (i) {
                          return SizedBox(
                            width: 48,
                            height: 56,
                            child: KeyboardListener(
                              focusNode: FocusNode(),
                              onKeyEvent: (e) => _onKeyEvent(i, e),
                              child: TextFormField(
                                controller: _digitCtrl[i],
                                focusNode: _focusNodes[i],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                onChanged: (v) => _onDigitChanged(i, v),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: Colors.white.withAlpha(18),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.white.withAlpha(51)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF10B981), width: 2),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 36),

                      // Verify Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _verify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                const Color(0xFF10B981).withAlpha(128),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Verify & Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Countdown / Resend
                      Center(
                        child: _secondsLeft > 0
                            ? RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(153),
                                    fontSize: 14,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Resend code in '),
                                    TextSpan(
                                      text: '${_secondsLeft}s',
                                      style: const TextStyle(
                                        color: Color(0xFF10B981),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : GestureDetector(
                                onTap: _resend,
                                child: const Text(
                                  'Resend Code',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

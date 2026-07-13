import 'dart:async';
import 'dart:math' as math;
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
    with TickerProviderStateMixin {
  static const _pinLength = 6;
  static const _timerSeconds = 60;

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
          VerifyOtpEvent(email: widget.email, otp: _otp),
        );
  }

  void _resend() {
    if (_secondsLeft > 0) return;
    for (final controller in _digitCtrl) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
    context.read<PhoneAuthBloc>().add(RequestOtpEvent(widget.email));
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PhoneAuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
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
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF021B13),
                  Color(0xFF063B2B),
                  Color(0xFF0F766E),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _liquidCtrl,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _LiquidOtpPainter(progress: _liquidCtrl.value),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 24,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _BackButton(onTap: () => Navigator.of(context).pop()),
                          const SizedBox(height: 40),
                          AnimatedBuilder(
                            animation: _liquidCtrl,
                            builder: (context, _) {
                              final glow = .55 +
                                  math.sin(_liquidCtrl.value * math.pi * 2) * .18;
                              return Container(
                                width: 74,
                                height: 74,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981)
                                          .withAlpha((90 * glow).round()),
                                      blurRadius: 28,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.mark_email_read_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Check your email',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: Colors.white.withAlpha(170),
                                fontSize: 14,
                                height: 1.6,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'We sent a 6-digit liquid OTP code to\n',
                                ),
                                TextSpan(
                                  text: widget.email,
                                  style: const TextStyle(
                                    color: Color(0xFFA7F3D0),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(_pinLength, _buildOtpBox),
                          ),
                          const SizedBox(height: 36),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _verify,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    const Color(0xFF10B981).withAlpha(128),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
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
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Center(
                            child: _secondsLeft > 0
                                ? RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(165),
                                        fontSize: 14,
                                      ),
                                      children: [
                                        const TextSpan(text: 'Resend code in '),
                                        TextSpan(
                                          text: '${_secondsLeft}s',
                                          style: const TextStyle(
                                            color: Color(0xFFA7F3D0),
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : TextButton(
                                    onPressed: _resend,
                                    child: const Text(
                                      'Resend Code',
                                      style: TextStyle(
                                        color: Color(0xFFA7F3D0),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOtpBox(int index) {
    return AnimatedBuilder(
      animation: Listenable.merge([_liquidCtrl, _focusNodes[index]]),
      builder: (context, _) {
        final isFocused = _focusNodes[index].hasFocus;
        final wave = math.sin((_liquidCtrl.value * math.pi * 2) + index * .65);
        return AnimatedScale(
          scale: isFocused ? 1.06 : 1,
          duration: const Duration(milliseconds: 180),
          child: SizedBox(
            width: 48,
            height: 58,
            child: KeyboardListener(
              focusNode: _keyNodes[index],
              onKeyEvent: (event) => _onKeyEvent(index, event),
              child: TextFormField(
                controller: _digitCtrl[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => _onDigitChanged(index, value),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: isFocused
                      ? Color.lerp(
                          const Color(0xFF10B981),
                          const Color(0xFF14B8A6),
                          (wave + 1) / 2,
                        )!.withAlpha(75)
                      : Colors.white.withAlpha(20),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: Colors.white.withAlpha(54)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: Color(0xFFA7F3D0),
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(24),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(42)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

class _LiquidOtpPainter extends CustomPainter {
  final double progress;

  _LiquidOtpPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [Color(0x3310B981), Color(0x2214B8A6)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final baseY = size.height * 0.66;
    path.moveTo(0, baseY);

    for (double x = 0; x <= size.width; x += 8) {
      final y = baseY +
          math.sin((x / size.width * math.pi * 2) + progress * math.pi * 2) * 18 +
          math.cos((x / size.width * math.pi * 4) + progress * math.pi * 2) * 8;
      path.lineTo(x, y);
    }

    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);

    final bubblePaint = Paint()..color = const Color(0x2610B981);
    for (int i = 0; i < 8; i++) {
      final dx = size.width * ((i * 0.17 + progress * 0.28) % 1.0);
      final dy = size.height * (0.18 + (i % 5) * 0.11);
      final radius = 12.0 + (i % 3) * 7.0;
      canvas.drawCircle(Offset(dx, dy), radius, bubblePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidOtpPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

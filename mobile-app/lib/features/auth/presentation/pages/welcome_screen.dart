import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/language_bloc.dart';
import '../../../../core/localization/language_event.dart';
import '../../../../core/localization/app_translations.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _contentController;
  late AnimationController _floatController;
  late AnimationController _shineController;

  late Animation<double> _heroScale;
  late Animation<double> _heroOpacity;
  late Animation<double> _contentOpacity;
  late Animation<Offset> _logoSlide;
  late Animation<Offset> _subtitleSlide;
  late Animation<Offset> _buttonSlide;
  late Animation<double> _floatY;
  late Animation<double> _shine;
  late Animation<double> _leaf1Rotate;
  late Animation<double> _leaf2Rotate;

  static const greenDarkColor = Color(0xFF0F5132);
  static const greenPrimaryColor = Color(0xFF198754);
  static const orangeColor = Color(0xFFE67E22);

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _shineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _heroScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOutBack),
    );
    _heroOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _heroController, curve: const Interval(0.0, 0.6)),
    );
    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );
    _logoSlide =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );
    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _buttonSlide =
        Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _floatY = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _shine = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shineController, curve: Curves.linear),
    );
    _leaf1Rotate = Tween<double>(begin: -0.35, end: 0.1).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _leaf2Rotate = Tween<double>(begin: 0.8, end: 0.4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Stagger: hero first, then content
    _heroController.forward().then((_) => _contentController.forward());
  }

  @override
  void dispose() {
    _heroController.dispose();
    _contentController.dispose();
    _floatController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = context.isUrdu;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7EF),
      body: Stack(
        children: [
          // Animated gradient background glow
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) {
              return Positioned(
                bottom: -120 + _floatY.value * 0.5,
                left: size.width * 0.05,
                right: size.width * 0.05,
                child: Container(
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE2F0D9).withOpacity(0.9),
                  ),
                ),
              );
            },
          ),

          // Floating leaf 1 (Top Left)
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) {
              return Positioned(
                top: size.height * 0.1 + _floatY.value * 1.2,
                left: 20,
                child: Transform.rotate(
                  angle: _leaf1Rotate.value,
                  child: const Icon(Icons.spa_rounded,
                      size: 24, color: Color(0x66198754)),
                ),
              );
            },
          ),

          // Floating leaf 2 (Top Right)
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) {
              return Positioned(
                top: size.height * 0.05 + _floatY.value,
                right: 40,
                child: Transform.rotate(
                  angle: _leaf2Rotate.value,
                  child: const Icon(Icons.spa_rounded,
                      size: 32, color: Color(0x77198754)),
                ),
              );
            },
          ),

          // Floating leaf 3 (Mid Left)
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) {
              return Positioned(
                top: size.height * 0.42 - _floatY.value * 0.8,
                left: 35,
                child: Transform.rotate(
                  angle: 0.25 + _floatY.value * 0.01,
                  child: const Icon(Icons.eco_rounded,
                      size: 22, color: Color(0x44198754)),
                ),
              );
            },
          ),

          // Floating leaf 4 (Mid Right)
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) {
              return Positioned(
                top: size.height * 0.38 + _floatY.value * 0.6,
                right: 28,
                child: Transform.rotate(
                  angle: -0.15 + _floatY.value * 0.01,
                  child: const Icon(Icons.spa_rounded,
                      size: 26, color: Color(0x55198754)),
                ),
              );
            },
          ),

          // Main content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: Directionality(
                    textDirection: context.textDirection,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // TOP: Logo & title
                        SlideTransition(
                          position: _logoSlide,
                          child: FadeTransition(
                            opacity: _contentOpacity,
                            child: Column(
                              children: [
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 68,
                                      height: 68,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: greenPrimaryColor
                                            .withOpacity(0.08),
                                        borderRadius:
                                            BorderRadius.circular(18),
                                      ),
                                      child: CustomPaint(
                                        painter: CartLogoPainter(
                                            color: greenPrimaryColor),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'GO FAST',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: greenDarkColor,
                                            fontStyle: FontStyle.italic,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        Text(
                                          'GROCERY',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: orangeColor,
                                            fontStyle: FontStyle.italic,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Go Fast Grocery',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF114B30),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // MIDDLE: Premium Custom Animated Grocery Illustration
                        FadeTransition(
                          opacity: _heroOpacity,
                          child: const _AnimatedGroceryIllustration(),
                        ),

                        // BOTTOM: subtitle, button, language
                        SlideTransition(
                          position: _subtitleSlide,
                          child: FadeTransition(
                            opacity: _contentOpacity,
                            child: Text(
                              context.tr('onboarding_subtitle'),
                              textAlign: TextAlign.center,
                              style: context.urStyle(
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF4A5568),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SlideTransition(
                          position: _buttonSlide,
                          child: FadeTransition(
                            opacity: _contentOpacity,
                            child: Column(
                              children: [
                                // Continue Button with ripple & glow
                                _AnimatedContinueButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pushNamed('/welcome');
                                  },
                                  label: context.tr('continue_button'),
                                ),
                                const SizedBox(height: 20),

                                // Language divider
                                Row(
                                  children: [
                                    const Expanded(
                                        child: Divider(
                                            color: Color(0xFFD1D5DB),
                                            thickness: 1)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12.0),
                                      child: Text(
                                        context.tr('select_language'),
                                        style: context.urStyle(
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4B5563),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                        child: Divider(
                                            color: Color(0xFFD1D5DB),
                                            thickness: 1)),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Language buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: _LanguageButton(
                                        label: 'English',
                                        icon: Icons.language_rounded,
                                        isSelected: !isUrdu,
                                        color: greenPrimaryColor,
                                        onTap: () => context
                                            .read<LanguageBloc>()
                                            .add(const ChangeLanguageEvent(
                                                Locale('en'))),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: _LanguageButton(
                                        label: 'اردو',
                                        icon: Icons.language_rounded,
                                        isSelected: isUrdu,
                                        color: greenPrimaryColor,
                                        isRtl: true,
                                        onTap: () => context
                                            .read<LanguageBloc>()
                                            .add(const ChangeLanguageEvent(
                                                Locale('ur'))),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Animated Continue Button
class _AnimatedContinueButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  const _AnimatedContinueButton(
      {required this.onPressed, required this.label});

  @override
  State<_AnimatedContinueButton> createState() =>
      _AnimatedContinueButtonState();
}

class _AnimatedContinueButtonState extends State<_AnimatedContinueButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _arrowController;
  late Animation<Offset> _arrowAnim;

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    _arrowAnim =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0.2, 0)).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F5132), Color(0xFF198754)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF198754).withOpacity(0.45),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: SlideTransition(
                  position: _arrowAnim,
                  child: const Icon(Icons.arrow_forward_rounded, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Language Button
class _LanguageButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final bool isRtl;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
    this.isRtl = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 46,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFF1F5F9),
            width: isSelected ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.08 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: isRtl
              ? [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(icon,
                      color: isSelected ? color : const Color(0xFF6B7280),
                      size: 18),
                ]
              : [
                  Icon(icon,
                      color: isSelected ? color : const Color(0xFF6B7280),
                      size: 18),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : const Color(0xFF1F2937),
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}

class CartLogoPainter extends CustomPainter {
  final Color color;
  CartLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.2)
      ..lineTo(size.width * 0.3, size.height * 0.2)
      ..lineTo(size.width * 0.42, size.height * 0.6)
      ..lineTo(size.width * 0.8, size.height * 0.6)
      ..lineTo(size.width * 0.9, size.height * 0.3)
      ..lineTo(size.width * 0.35, size.height * 0.3);

    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(size.width * 0.48, size.height * 0.74), 5, fillPaint);
    canvas.drawCircle(
        Offset(size.width * 0.76, size.height * 0.74), 5, fillPaint);

    canvas.drawLine(
        Offset(size.width * 0.05, size.height * 0.35),
        Offset(size.width * 0.23, size.height * 0.35),
        paint..strokeWidth = 3);
    canvas.drawLine(
        Offset(size.width * 0.12, size.height * 0.45),
        Offset(size.width * 0.26, size.height * 0.45),
        paint..strokeWidth = 3);
    canvas.drawLine(
        Offset(size.width * 0.08, size.height * 0.55),
        Offset(size.width * 0.28, size.height * 0.55),
        paint..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnimatedGroceryIllustration extends StatefulWidget {
  const _AnimatedGroceryIllustration();

  @override
  State<_AnimatedGroceryIllustration> createState() => _AnimatedGroceryIllustrationState();
}

class _AnimatedGroceryIllustrationState extends State<_AnimatedGroceryIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * math.pi;
        final cartY = math.sin(t) * 8;
        final item1Y = math.sin(t + 1) * 12;
        final item2Y = math.cos(t + 2) * 10;
        final item3Y = math.sin(t + 3) * 14;

        return SizedBox(
          height: 240,
          width: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Radial background glow pulse
              Container(
                width: 180 + math.sin(t) * 10,
                height: 180 + math.sin(t) * 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE8F5E9).withOpacity(0.6),
                ),
              ),

              // Central Shopping Basket
              Transform.translate(
                offset: Offset(0, cartY),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF198754).withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shopping_basket_rounded,
                    size: 64,
                    color: Color(0xFF198754),
                  ),
                ),
              ),

              // Floating item 1 (Apple - Top Left)
              Positioned(
                top: 30,
                left: 40,
                child: Transform.translate(
                  offset: Offset(0, item1Y),
                  child: Transform.rotate(
                    angle: math.sin(t) * 0.1,
                    child: _buildFloatingIcon(Icons.apple_rounded, Colors.redAccent, 40),
                  ),
                ),
              ),

              // Floating item 2 (Eco Leaf - Top Right)
              Positioned(
                top: 25,
                right: 40,
                child: Transform.translate(
                  offset: Offset(0, item2Y),
                  child: Transform.rotate(
                    angle: math.cos(t) * 0.15,
                    child: _buildFloatingIcon(Icons.eco_rounded, Colors.green, 38),
                  ),
                ),
              ),

              // Floating item 3 (Fast Delivery - Bottom Left)
              Positioned(
                bottom: 30,
                left: 30,
                child: Transform.translate(
                  offset: Offset(0, item3Y),
                  child: Transform.rotate(
                    angle: math.sin(t + 2) * 0.12,
                    child: _buildFloatingIcon(Icons.local_shipping_rounded, Colors.orange, 38),
                  ),
                ),
              ),

              // Floating item 4 (Store - Bottom Right)
              Positioned(
                bottom: 25,
                right: 30,
                child: Transform.translate(
                  offset: Offset(0, item1Y * -1),
                  child: Transform.rotate(
                    angle: math.cos(t + 1) * 0.1,
                    child: _buildFloatingIcon(Icons.store_rounded, Colors.blueAccent, 40),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingIcon(IconData icon, Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size * 0.6),
    );
  }
}


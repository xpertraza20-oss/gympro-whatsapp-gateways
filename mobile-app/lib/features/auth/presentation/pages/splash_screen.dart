import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _pulseController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoRotation;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _logoRotation = Tween<double>(begin: -0.4, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _pulse = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _logoController.forward();

    // Check auth status and navigate after exactly 3 seconds
    Future.delayed(const Duration(milliseconds: 3000), () async {
      if (!mounted) return;

      try {
        const secureStorage = FlutterSecureStorage();
        final token = await secureStorage.read(key: 'jwt_access_token');
        final role = await secureStorage.read(key: 'user_role');
        final profileStatus = await secureStorage.read(key: 'profile_status');

        if (token != null && token.isNotEmpty) {
          if (profileStatus == 'incomplete') {
            if (role == 'shopkeeper') {
              Navigator.of(context).pushReplacementNamed('/shopkeeper_register');
            } else if (role == 'rider') {
              Navigator.of(context).pushReplacementNamed('/rider_register');
            } else {
              Navigator.of(context).pushReplacementNamed('/customer_register');
            }
          } else if (profileStatus == 'pending') {
            Navigator.of(context).pushReplacementNamed('/pending_approval');
          } else {
            if (role == 'shopkeeper') {
              Navigator.of(context).pushReplacementNamed('/shopkeeper_dashboard');
            } else if (role == 'rider') {
              Navigator.of(context).pushReplacementNamed('/rider_dashboard');
            } else {
              Navigator.of(context).pushReplacementNamed('/customer_dashboard');
            }
          }
        } else {
          Navigator.of(context).pushReplacementNamed('/onboarding');
        }
      } catch (e) {
        debugPrint('Splash Auth check error: $e');
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Centered Logo with premium clean elastic scaling animation on solid white
          Center(
            child: _AnimatedLogoWidget(),
          ),
        ],
      ),
    );
  }
}

class _AnimatedLogoWidget extends StatefulWidget {
  const _AnimatedLogoWidget();

  @override
  State<_AnimatedLogoWidget> createState() => _AnimatedLogoWidgetState();
}

class _AnimatedLogoWidgetState extends State<_AnimatedLogoWidget>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.3, curve: Curves.easeIn)),
    );
    _rotate = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: Transform.rotate(
              angle: _rotate.value * math.pi,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B4BF4).withOpacity(0.12),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: ClipOval(
          child: Image.asset(
            'assets/images/Logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.shopping_basket_rounded,
                size: 64,
                color: Color(0xFF6B4BF4),
              );
            },
          ),
        ),
      ),
    );
  }
}

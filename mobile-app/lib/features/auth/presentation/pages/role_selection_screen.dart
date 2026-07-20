import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_screen.dart';
import '../../../../core/localization/language_bloc.dart';
import '../../../../core/localization/language_event.dart';
import '../../../../core/localization/app_translations.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animCtrl;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    
    // Animation Controller for staggered entry
    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Header entry animation
    _headerFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));

    // Staggered list items animations
    _fadeAnimations = List.generate(3, (index) {
      double start = 0.2 + (index * 0.15);
      double end = (start + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _animCtrl,
        curve: Interval(start, end, curve: Curves.easeIn),
      );
    });

    _slideAnimations = List.generate(3, (index) {
      double start = 0.2 + (index * 0.15);
      double end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0.0, 0.25),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ));
    });

    // Start animating
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = context.isUrdu;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background Decorative Orb
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEFF6FF).withOpacity(0.55),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Directionality(
                  textDirection: context.textDirection,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                    // Header Actions Row (Back Button, Language Toggle, Dots Grid)
                    FadeTransition(
                      opacity: _headerFade,
                      child: SlideTransition(
                        position: _headerSlide,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back Button
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).maybePop();
                              },
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
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),

                            // Language Toggle Pill
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.all(3),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      context.read<LanguageBloc>().add(const ChangeLanguageEvent(Locale('en')));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: !isUrdu ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: !isUrdu
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.06),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1.5),
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: const Text(
                                        'EN',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      context.read<LanguageBloc>().add(const ChangeLanguageEvent(Locale('ur')));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isUrdu ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: isUrdu
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.06),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1.5),
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: const Text(
                                        'اردو',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Decorative Dots Grid (3x3)
                            _buildDotsGrid(),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Title
                    FadeTransition(
                      opacity: _headerFade,
                      child: SlideTransition(
                        position: _headerSlide,
                        child: Column(
                          children: [
                            Text(
                              context.tr('choose_role'),
                              style: context.urStyle(
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr('role_tagline'),
                              style: context.urStyle(
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),

                    // Progress Dots Indicator
                    FadeTransition(
                      opacity: _headerFade,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B4BF4),
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
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // ─── CARDS CONTAINER (Dynamic scaling heights) ───
                    Builder(
                      builder: (context) {
                        final double calculatedCardHeight = (size.height * 0.19).clamp(145.0, 205.0);
                        final bool useSmallStyle = size.height < 780;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // CARD 1: CUSTOMER
                            FadeTransition(
                              opacity: _fadeAnimations[0],
                              child: SlideTransition(
                                position: _slideAnimations[0],
                                child: SizedBox(
                                  height: calculatedCardHeight,
                                  child: _buildRoleCard(
                                    context: context,
                                    stepNumber: "1",
                                    role: 'customer',
                                    title: context.tr('customer'),
                                    description: context.tr('customer_desc'),
                                    imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuCTQCgIGA28tX3xVpiSya8p63owZcKVbMw7JikVpQlWdqeR1Ml2Uwy1PAt8LXrtBfTPEJMFkUIL7XcdiE5DBCKAKfp_U6NKpsErm1ARhQX3H9GMk5qiXzrs804O9jvuybkunZASlM4F4TT3Nl2LcYOU4D0wKgtThE57cU1Vl_6pi7Shf1fMWqDnNaIrcsSDNNYakpWYF2tn-TPn1Q8-JMdkRMbfFMoYV7Cxv45akaHg7UVmN3jzu-WT",
                                    bgColors: [const Color(0xFFF9F9FF), Colors.white],
                                    themeColor: const Color(0xFF6B4BF4),
                                    fallbackIcon: Icons.shopping_bag_rounded,
                                    isSmall: useSmallStyle,
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(height: useSmallStyle ? 12 : 16),

                            // CARD 2: SHOPKEEPER
                            FadeTransition(
                              opacity: _fadeAnimations[1],
                              child: SlideTransition(
                                position: _slideAnimations[1],
                                child: SizedBox(
                                  height: calculatedCardHeight,
                                  child: _buildRoleCard(
                                    context: context,
                                    stepNumber: "2",
                                    role: 'shopkeeper',
                                    title: context.tr('shopkeeper_title'),
                                    description: context.tr('shopkeeper_desc'),
                                    imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuAM6j_Xpem4VKq4Sfc7tMcz0YArj4aKjba3PQwuHlZZO_XP7rzaEVKeZnuf1OpwSjKfeLvOWVY_PdmO3RSl4NHuzAtAuhHHGxYmsGnVRZFJHIzOQcrXrJAKzNrHUKzYMxN3A9RiKClkv5k3tsns28QxDnYfVAQP9LhOhQZK6Q6wgSAOQlcL7Sr2le62T_Dc4DyKgx0brcs8qYzflHcDZtWiIe5ebspwy0VskmtbQQaXskJ6NFxggkxc",
                                    bgColors: [const Color(0xFFF6FFF8), Colors.white],
                                    themeColor: const Color(0xFF10B981),
                                    fallbackIcon: Icons.storefront_rounded,
                                    isSmall: useSmallStyle,
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(height: useSmallStyle ? 12 : 16),

                            // CARD 3: RIDER
                            FadeTransition(
                              opacity: _fadeAnimations[2],
                              child: SlideTransition(
                                position: _slideAnimations[2],
                                child: SizedBox(
                                  height: calculatedCardHeight,
                                  child: _buildRoleCard(
                                    context: context,
                                    stepNumber: "3",
                                    role: 'rider',
                                    title: context.tr('rider'),
                                    description: context.tr('rider_desc'),
                                    imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuAH-k6dxQU8-P0_BjRvlT51eImzjOFNRuenyDWbqfzU-IPN5y6tdSPLlwWL06-9Z_Jss1mSUHouGi4dMi_4-Zv27KbbaDZzti2wScQvfXsywCmqOoC1VQYxek5XSVa0fUrPrtCXxh9PYAQXdEv-mVQcmM7BmhqFzeXdJBfDHEErE1xp-XmdstFEUVPQDE4jvngfKXqtwIaup8VcJlyLA2cMKGUaNezx_YBiYdUAwnaPmQfAR3V2U3QX",
                                    bgColors: [const Color(0xFFFFF9F3), Colors.white],
                                    themeColor: const Color(0xFFF97316),
                                    fallbackIcon: Icons.delivery_dining_rounded,
                                    isSmall: useSmallStyle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                    const SizedBox(height: 16),

                    // Secure Footer
                    FadeTransition(
                      opacity: _headerFade,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF6B4BF4)),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('data_secure'),
                            style: context.urStyle(
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
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
        itemCount: 9,
        itemBuilder: (context, index) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String stepNumber,
    required String role,
    required String title,
    required String description,
    required String imageUrl,
    required List<Color> bgColors,
    required Color themeColor,
    required IconData fallbackIcon,
    required bool isSmall,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LoginScreen(role: role),
              ),
            );
          },
          splashColor: themeColor.withOpacity(0.05),
          highlightColor: themeColor.withOpacity(0.01),
          child: Stack(
            children: [
              // White decorative curve shape in top right corner
              Positioned(
                top: -24,
                right: -24,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.35),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(60),
                    ),
                  ),
                ),
              ),

              // Absolute positioned Chevron Right icon container (vertically centered)
              Positioned(
                right: 18,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: themeColor,
                      size: 18,
                    ),
                  ),
                ),
              ),

              // Responsive content row
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Styled Avatar Container
                      Container(
                        width: isSmall ? 60 : 70,
                        height: isSmall ? 60 : 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.all(2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: themeColor,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [themeColor.withOpacity(0.05), themeColor.withOpacity(0.15)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Icon(fallbackIcon, color: themeColor, size: isSmall ? 26 : 30),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Title & Description Column
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 36.0), // Prevent text touching Chevron
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: themeColor,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      stepNumber,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: context.urStyle(
                                        style: TextStyle(
                                          fontSize: isSmall ? 16 : 18,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.urStyle(
                                  style: TextStyle(
                                    fontSize: isSmall ? 11.5 : 12.5,
                                    color: const Color(0xFF64748B),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

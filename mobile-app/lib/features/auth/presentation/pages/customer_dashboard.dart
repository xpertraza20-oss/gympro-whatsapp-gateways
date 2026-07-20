import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/phone_auth_bloc.dart';
import '../../../product_catalog/presentation/pages/shop_menu_screen.dart';


// ─── DATA MODELS ─────────────────────────────────────────────────────────────

class ShopModel {
  final String name;
  final String category;
  final String imageEmoji;
  final String distance;
  final String deliveryTime;
  final double rating;
  final int reviewCount;
  final bool isOpen;
  final String deliveryFee;
  final Color accentColor;

  const ShopModel({
    required this.name,
    required this.category,
    required this.imageEmoji,
    required this.distance,
    required this.deliveryTime,
    required this.rating,
    required this.reviewCount,
    required this.isOpen,
    required this.deliveryFee,
    required this.accentColor,
  });
}

class CategoryModel {
  final String name;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const CategoryModel({
    required this.name,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

class BannerModel {
  final String title;
  final String subtitle;
  final String badge;
  final List<Color> gradientColors;
  final IconData icon;

  const BannerModel({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.gradientColors,
    required this.icon,
  });
}

// ─── DUMMY DATA ───────────────────────────────────────────────────────────────

final List<BannerModel> _dummyBanners = [
  const BannerModel(
    title: 'Fresh Groceries\nDelivered Fast',
    subtitle: 'Order from top shops near you',
    badge: '🛒 Free Delivery Today',
    gradientColors: [Color(0xFF006E2F), Color(0xFF00A651)],
    icon: Icons.eco_rounded,
  ),
  const BannerModel(
    title: 'Ramzan Special\nOffer 30% OFF',
    subtitle: 'On all Grocery & Dairy items',
    badge: '🔥 Limited Time',
    gradientColors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    icon: Icons.local_offer_rounded,
  ),
  const BannerModel(
    title: 'Pharmacy\nAt Your Door',
    subtitle: 'Medicines delivered in 20 mins',
    badge: '💊 24/7 Available',
    gradientColors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
    icon: Icons.medical_services_rounded,
  ),
  const BannerModel(
    title: 'Fresh Meat\nPremium Cuts',
    subtitle: 'Butcher-fresh, hygiene-certified',
    badge: '🥩 Order Now',
    gradientColors: [Color(0xFFB91C1C), Color(0xFFEF4444)],
    icon: Icons.set_meal_rounded,
  ),
];

final List<CategoryModel> _dummyCategories = [
  CategoryModel(
    name: 'Grocery',
    icon: Icons.shopping_basket_rounded,
    color: const Color(0xFF006E2F),
    bgColor: const Color(0xFFDCFCE7),
  ),
  CategoryModel(
    name: 'Pharmacy',
    icon: Icons.local_pharmacy_rounded,
    color: const Color(0xFF0284C7),
    bgColor: const Color(0xFFE0F2FE),
  ),
  CategoryModel(
    name: 'Meat',
    icon: Icons.set_meal_rounded,
    color: const Color(0xFFB91C1C),
    bgColor: const Color(0xFFFEE2E2),
  ),
  CategoryModel(
    name: 'Dairy',
    icon: Icons.egg_rounded,
    color: const Color(0xFFD97706),
    bgColor: const Color(0xFFFEF3C7),
  ),
  CategoryModel(
    name: 'Bakery',
    icon: Icons.bakery_dining_rounded,
    color: const Color(0xFF7C3AED),
    bgColor: const Color(0xFFF3E8FF),
  ),
  CategoryModel(
    name: 'Veggies',
    icon: Icons.grass_rounded,
    color: const Color(0xFF059669),
    bgColor: const Color(0xFFD1FAE5),
  ),
  CategoryModel(
    name: 'Drinks',
    icon: Icons.local_drink_rounded,
    color: const Color(0xFF0891B2),
    bgColor: const Color(0xFFCFFAFE),
  ),
  CategoryModel(
    name: 'Snacks',
    icon: Icons.fastfood_rounded,
    color: const Color(0xFFEA580C),
    bgColor: const Color(0xFFFFF7ED),
  ),
];

final List<ShopModel> _dummyShops = [
  ShopModel(
    name: 'Al-Fatah General Store',
    category: 'Grocery',
    imageEmoji: '🏪',
    distance: '0.8 km',
    deliveryTime: '15-20 min',
    rating: 4.8,
    reviewCount: 312,
    isOpen: true,
    deliveryFee: 'Free',
    accentColor: const Color(0xFF006E2F),
  ),
  ShopModel(
    name: 'Shifa Medical Store',
    category: 'Pharmacy',
    imageEmoji: '💊',
    distance: '1.2 km',
    deliveryTime: '20-30 min',
    rating: 4.6,
    reviewCount: 189,
    isOpen: true,
    deliveryFee: 'Rs. 49',
    accentColor: const Color(0xFF0284C7),
  ),
  ShopModel(
    name: 'Islamia Bakery & Sweets',
    category: 'Bakery',
    imageEmoji: '🥐',
    distance: '0.5 km',
    deliveryTime: '10-15 min',
    rating: 4.9,
    reviewCount: 547,
    isOpen: true,
    deliveryFee: 'Free',
    accentColor: const Color(0xFF7C3AED),
  ),
  ShopModel(
    name: 'Lahori Meat House',
    category: 'Meat',
    imageEmoji: '🥩',
    distance: '2.1 km',
    deliveryTime: '25-35 min',
    rating: 4.5,
    reviewCount: 203,
    isOpen: false,
    deliveryFee: 'Rs. 79',
    accentColor: const Color(0xFFB91C1C),
  ),
  ShopModel(
    name: 'Dairy Fresh Punjab',
    category: 'Dairy',
    imageEmoji: '🥛',
    distance: '1.5 km',
    deliveryTime: '20-25 min',
    rating: 4.7,
    reviewCount: 421,
    isOpen: true,
    deliveryFee: 'Free',
    accentColor: const Color(0xFFD97706),
  ),
  ShopModel(
    name: 'Green Valley Vegetables',
    category: 'Veggies',
    imageEmoji: '🥦',
    distance: '0.3 km',
    deliveryTime: '10-15 min',
    rating: 4.4,
    reviewCount: 98,
    isOpen: true,
    deliveryFee: 'Rs. 29',
    accentColor: const Color(0xFF059669),
  ),
];

// ─── MAIN DASHBOARD SCREEN ────────────────────────────────────────────────────

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard>
    with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  int _currentBannerIndex = 0;
  String _selectedCategory = 'All';
  String _deliveryAddress = 'Block D, Model Town, Lahore';

  late PageController _bannerController;

  static const _primaryColor = Color(0xFF006E2F);
  static const _primaryLight = Color(0xFF00A651);
  static const _bgColor = Color(0xFFF8FAF9);

  @override
  void initState() {
    super.initState();
    _bannerController = PageController(viewportFraction: 0.92);
    Future.delayed(const Duration(seconds: 3), _autoScrollBanner);
  }

  void _autoScrollBanner() {
    if (!mounted) return;
    final next = (_currentBannerIndex + 1) % _dummyBanners.length;
    _bannerController.animateToPage(
      next,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(seconds: 4), _autoScrollBanner);
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  List<ShopModel> get _filteredShops {
    if (_selectedCategory == 'All') return _dummyShops;
    return _dummyShops.where((s) => s.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    return BlocListener<PhoneAuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        body: IndexedStack(
          index: _currentNavIndex,
          children: [
            _buildHomeTab(),
            _buildCartTab(),
            _buildOrdersTab(),
            _buildProfileTab(),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HOME TAB
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildHomeTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(child: _buildSearchBar()),
        SliverToBoxAdapter(child: _buildBannerCarousel()),
        SliverToBoxAdapter(child: _buildCategoriesSection()),
        SliverToBoxAdapter(child: _buildShopsHeader()),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildShopCard(_filteredShops[index]),
            childCount: _filteredShops.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  // ── Custom Sliver AppBar ──────────────────────────────────────────────────
  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.black12,
      toolbarHeight: 70,
      title: GestureDetector(
        onTap: _showAddressSheet,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_on_rounded, color: _primaryColor, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivering to',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _deliveryAddress,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _primaryColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              onPressed: () {},
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_outlined, color: Color(0xFF374151), size: 22),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Search functionality coming soon!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Search shops, products, categories...',
                  style: TextStyle(color: Color(0xFFB0B8C1), fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: _primaryColor, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Filter',
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Banner Carousel ───────────────────────────────────────────────────────
  Widget _buildBannerCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 175,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (i) => setState(() => _currentBannerIndex = i),
            itemCount: _dummyBanners.length,
            itemBuilder: (_, i) => _buildBannerCard(_dummyBanners[i]),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _dummyBanners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentBannerIndex == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentBannerIndex == i ? _primaryColor : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildBannerCard(BannerModel banner) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: banner.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: banner.gradientColors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            banner.badge,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          banner.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          banner.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Order Now',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: banner.gradientColors.first,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(banner.icon, color: Colors.white, size: 36),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Categories Section ────────────────────────────────────────────────────
  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _dummyCategories.length,
            itemBuilder: (_, i) => _buildCategoryChip(_dummyCategories[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(CategoryModel cat) {
    final isSelected = _selectedCategory == cat.name;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = isSelected ? 'All' : cat.name),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? cat.color : cat.bgColor,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: cat.color.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Icon(cat.icon, color: isSelected ? Colors.white : cat.color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              cat.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? cat.color : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shops Header ──────────────────────────────────────────────────────────
  Widget _buildShopsHeader() {
    final count = _filteredShops.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedCategory == 'All' ? 'Nearby Shops' : '$_selectedCategory Shops',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                '$count ${count == 1 ? "shop" : "shops"} available near you',
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.sort_rounded, size: 14, color: Color(0xFF6B7280)),
                SizedBox(width: 4),
                Text(
                  'Sort',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shop Card ─────────────────────────────────────────────────────────────
  Widget _buildShopCard(ShopModel shop) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShopMenuScreen(
              shop: ShopMenuData(
                id: shop.name,
                name: shop.name,
                category: shop.category,
                imageEmoji: shop.imageEmoji,
                distance: shop.distance,
                deliveryTime: shop.deliveryTime,
                rating: shop.rating,
                reviewCount: shop.reviewCount,
                isOpen: shop.isOpen,
                deliveryFee: shop.deliveryFee,
                accentColor: shop.accentColor,
              ),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Shop Image Banner
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      shop.accentColor.withOpacity(0.15),
                      shop.accentColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Large emoji placeholder — replace with CachedNetworkImage in production
                    Center(
                      child: Text(shop.imageEmoji, style: const TextStyle(fontSize: 64)),
                    ),
                    // Open / Closed Badge
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: shop.isOpen ? const Color(0xFF006E2F) : const Color(0xFF6B7280),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: shop.isOpen ? const Color(0xFF86EFAC) : Colors.white54,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              shop.isOpen ? 'Open' : 'Closed',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Category Chip
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          shop.category,
                          style: TextStyle(
                            color: shop.accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info Section
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Rating Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          shop.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 16),
                          const SizedBox(width: 2),
                          Text(
                            shop.rating.toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF374151),
                            ),
                          ),
                          Text(
                            ' (${shop.reviewCount})',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Distance / Time / Delivery Fee Row
                  Row(
                    children: [
                      _infoChip(Icons.location_on_rounded, shop.distance, const Color(0xFF6B7280)),
                      const SizedBox(width: 8),
                      _infoChip(Icons.access_time_rounded, shop.deliveryTime, const Color(0xFF6B7280)),
                      const SizedBox(width: 8),
                      _infoChip(
                        Icons.delivery_dining_rounded,
                        shop.deliveryFee,
                        shop.deliveryFee == 'Free' ? const Color(0xFF006E2F) : const Color(0xFF6B7280),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // CTA Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: shop.accentColor.withOpacity(0.4)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text(
                            'View Menu',
                            style: TextStyle(
                              fontSize: 13,
                              color: shop.accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: shop.isOpen ? () {} : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: shop.accentColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFD1D5DB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Order Now',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BOTTOM NAV BAR
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    const items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.shopping_cart_outlined, 'label': 'Cart'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Orders'},
      {'icon': Icons.person_rounded, 'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final isActive = _currentNavIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentNavIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFFDCFCE7) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          items[i]['icon'] as IconData,
                          color: isActive ? _primaryColor : const Color(0xFF9CA3AF),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive ? _primaryColor : const Color(0xFF9CA3AF),
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PLACEHOLDER TABS
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildCartTab() {
    return _buildPlaceholderTab(
      icon: Icons.shopping_cart_outlined,
      title: 'Your Cart is Empty',
      subtitle: 'Browse shops and add items to start shopping',
      buttonLabel: 'Browse Shops',
      color: _primaryColor,
      onTap: () => setState(() => _currentNavIndex = 0),
    );
  }

  Widget _buildOrdersTab() {
    return _buildPlaceholderTab(
      icon: Icons.receipt_long_rounded,
      title: 'No Orders Yet',
      subtitle: 'Place your first order and track it live here',
      buttonLabel: 'Start Shopping',
      color: const Color(0xFF0284C7),
      onTap: () => setState(() => _currentNavIndex = 0),
    );
  }

  Widget _buildProfileTab() {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937), fontSize: 18),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.read<PhoneAuthBloc>().add(LogoutEvent()),
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
            label: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryColor, _primaryLight],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 38),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ahmed Raza',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'ahmed@example.com',
                        style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.verified_rounded, color: _primaryColor, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Verified Customer',
                            style: TextStyle(
                              fontSize: 12,
                              color: _primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Menu Items
          _profileMenuItem(
            icon: Icons.receipt_long_rounded,
            label: 'My Orders',
            color: const Color(0xFF0284C7),
          ),
          _profileMenuItem(
            icon: Icons.location_on_rounded,
            label: 'Saved Addresses',
            color: _primaryColor,
          ),
          _profileMenuItem(
            icon: Icons.payment_rounded,
            label: 'Payment Methods',
            color: const Color(0xFF7C3AED),
          ),
          _profileMenuItem(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            color: const Color(0xFFD97706),
          ),
          _profileMenuItem(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            color: const Color(0xFF6B7280),
          ),
          _profileMenuItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            color: const Color(0xFF6B7280),
          ),
        ],
      ),
    );
  }

  Widget _profileMenuItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFD1D5DB)),
        onTap: () {},
      ),
    );
  }

  Widget _buildPlaceholderTab({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 50, color: color),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ADDRESS BOTTOM SHEET
  // ──────────────────────────────────────────────────────────────────────────
  void _showAddressSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: _primaryColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Select Delivery Address',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...[
                'Block D, Model Town, Lahore',
                'Gulberg III, Lahore',
                'Defence Phase 5, Lahore',
              ].map(
                (addr) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on_outlined, color: _primaryColor, size: 18),
                  ),
                  title: Text(addr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  trailing: _deliveryAddress == addr
                      ? const Icon(Icons.check_circle_rounded, color: _primaryColor, size: 20)
                      : null,
                  onTap: () {
                    setState(() => _deliveryAddress = addr);
                    Navigator.pop(context);
                  },
                ),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_location_alt_outlined, color: Color(0xFFD97706), size: 18),
                ),
                title: const Text(
                  'Add New Address',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

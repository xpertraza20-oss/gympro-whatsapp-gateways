import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../../checkout/presentation/pages/checkout_screen.dart';


// ─── SHOP DATA MODEL (REUSED FROM DASHBOARD) ──────────────────────────────────
class ShopMenuData {
  final String id;
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

  const ShopMenuData({
    required this.id,
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

// ─── DUMMY PRODUCTS MAPPED BY SHOP ID ─────────────────────────────────────────
final Map<String, List<Product>> _dummyShopProducts = {
  // Al-Fatah General Store
  'Al-Fatah General Store': [
    const Product(id: 'g1', title: 'Organic Red Apples', price: 250, unit: '1 kg', category: 'Fruits', imageUrl: '🍎', stock: 50, shopId: 'Al-Fatah General Store', shopName: 'Al-Fatah General Store'),
    const Product(id: 'g2', title: 'Fresh Yellow Bananas', price: 150, unit: '1 dozen', category: 'Fruits', imageUrl: '🍌', stock: 40, shopId: 'Al-Fatah General Store', shopName: 'Al-Fatah General Store'),
    const Product(id: 'g3', title: 'Farm Fresh Eggs', price: 320, unit: '1 dozen', category: 'Dairy', imageUrl: '🥚', stock: 100, shopId: 'Al-Fatah General Store', shopName: 'Al-Fatah General Store'),
    const Product(id: 'g4', title: 'Premium Milk Pasteurized', price: 180, unit: '1 Litre', category: 'Dairy', imageUrl: '🥛', stock: 60, shopId: 'Al-Fatah General Store', shopName: 'Al-Fatah General Store'),
    const Product(id: 'g5', title: 'Fine Wheat Flour (Atta)', price: 650, unit: '5 kg', category: 'Staples', imageUrl: '🌾', stock: 25, shopId: 'Al-Fatah General Store', shopName: 'Al-Fatah General Store'),
    const Product(id: 'g6', title: 'Basmati Rice Super', price: 350, unit: '1 kg', category: 'Staples', imageUrl: '🍚', stock: 35, shopId: 'Al-Fatah General Store', shopName: 'Al-Fatah General Store'),
    const Product(id: 'g7', title: 'Pure Forest Honey', price: 950, unit: '500 g', category: 'Snacks', imageUrl: '🍯', stock: 15, shopId: 'Al-Fatah General Store', shopName: 'Al-Fatah General Store'),
    const Product(id: 'g8', title: 'Red Chili Powder Pack', price: 120, unit: '200 g', category: 'Staples', imageUrl: '🌶️', stock: 45, shopId: 'Al-Fatah General Store', shopName: 'Al-Fatah General Store'),
  ],
  // Shifa Medical Store
  'Shifa Medical Store': [
    const Product(id: 'p1', title: 'Panadol Extra Tablets', price: 90, unit: '1 pack', category: 'Medicines', imageUrl: '💊', stock: 150, shopId: 'Shifa Medical Store', shopName: 'Shifa Medical Store'),
    const Product(id: 'p2', title: 'Ponstan 250mg Relief', price: 75, unit: '1 pack', category: 'Medicines', imageUrl: '💊', stock: 80, shopId: 'Shifa Medical Store', shopName: 'Shifa Medical Store'),
    const Product(id: 'p3', title: 'Surgical Face Masks', price: 150, unit: '10 pcs', category: 'Wellness', imageUrl: '😷', stock: 200, shopId: 'Shifa Medical Store', shopName: 'Shifa Medical Store'),
    const Product(id: 'p4', title: 'Advanced Hand Sanitizer', price: 220, unit: '100 ml', category: 'Wellness', imageUrl: '🧴', stock: 90, shopId: 'Shifa Medical Store', shopName: 'Shifa Medical Store'),
    const Product(id: 'p5', title: 'Vitamin C Effervescent', price: 350, unit: '1 pack', category: 'Wellness', imageUrl: '🍊', stock: 70, shopId: 'Shifa Medical Store', shopName: 'Shifa Medical Store'),
    const Product(id: 'p6', title: 'Digital Body Thermometer', price: 650, unit: '1 unit', category: 'Medical Devices', imageUrl: '🌡️', stock: 30, shopId: 'Shifa Medical Store', shopName: 'Shifa Medical Store'),
  ],
  // Islamia Bakery & Sweets
  'Islamia Bakery & Sweets': [
    const Product(id: 'b1', title: 'Vanilla Sponge Cake', price: 280, unit: '1 unit', category: 'Cakes', imageUrl: '🍰', stock: 20, shopId: 'Islamia Bakery & Sweets', shopName: 'Islamia Bakery & Sweets'),
    const Product(id: 'b2', title: 'Chocolate Croissant', price: 160, unit: '1 unit', category: 'Pastries', imageUrl: '🥐', stock: 30, shopId: 'Islamia Bakery & Sweets', shopName: 'Islamia Bakery & Sweets'),
    const Product(id: 'b3', title: 'Freshly Baked Rusk', price: 180, unit: '1 pack', category: 'Snacks', imageUrl: '🍞', stock: 40, shopId: 'Islamia Bakery & Sweets', shopName: 'Islamia Bakery & Sweets'),
    const Product(id: 'b4', title: 'Large Milk Bread', price: 190, unit: '1 unit', category: 'Breads', imageUrl: '🍞', stock: 50, shopId: 'Islamia Bakery & Sweets', shopName: 'Islamia Bakery & Sweets'),
    const Product(id: 'b5', title: 'Savory Chicken Patties', price: 90, unit: '1 unit', category: 'Snacks', imageUrl: '🥧', stock: 60, shopId: 'Islamia Bakery & Sweets', shopName: 'Islamia Bakery & Sweets'),
    const Product(id: 'b6', title: 'Chocolate Chip Cookies', price: 350, unit: '250 g', category: 'Snacks', imageUrl: '🍪', stock: 35, shopId: 'Islamia Bakery & Sweets', shopName: 'Islamia Bakery & Sweets'),
  ],
};

// Fallback products list if shop not matched
final List<Product> _defaultProducts = [
  const Product(id: 'df1', title: 'Standard Grocery Item', price: 100, unit: '1 unit', category: 'General', imageUrl: '📦', stock: 10, shopId: 'Default Shop', shopName: 'Default Shop'),
];

class ShopMenuScreen extends StatefulWidget {
  final ShopMenuData shop;

  const ShopMenuScreen({
    super.key,
    required this.shop,
  });

  @override
  State<ShopMenuScreen> createState() => _ShopMenuScreenState();
}

class _ShopMenuScreenState extends State<ShopMenuScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  TabController? _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  List<Product> _shopProducts = [];
  bool _isLoading = false;

  List<String> get _categories {
    final Set<String> cats = {'All'};
    for (var prod in _shopProducts) {
      cats.add(prod.category);
    }
    return cats.toList();
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final repo = RepositoryProvider.of<ProductRepository>(context);
      final list = await repo.getProducts(page: 1, limit: 100);
      
      final shopProducts = list.where((p) => 
        p.shopId == widget.shop.name || 
        p.shopName == widget.shop.name || 
        p.shopId == widget.shop.id ||
        p.shopName == widget.shop.id
      ).toList();
      
      final finalProducts = shopProducts.isNotEmpty ? shopProducts : list;

      if (mounted) {
        setState(() {
          _shopProducts = finalProducts;
          _isLoading = false;
        });
        _initTabController();
      }
    } catch (e) {
      print("[ShopMenuScreen] Failed to load database products: $e");
      if (mounted) {
        setState(() {
          _shopProducts = _dummyShopProducts[widget.shop.name] ?? _defaultProducts;
          _isLoading = false;
        });
        _initTabController();
      }
    }
  }

  void _initTabController() {
    _tabController?.dispose();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController!.addListener(() {
      if (!mounted) return;
      setState(() {
        _selectedCategory = _categories[_tabController!.index];
      });
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    return _shopProducts.where((p) {
      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesSearch = p.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _showConflictDialog(BuildContext context, Product pendingProduct, String conflictShopName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 28),
            SizedBox(width: 8),
            Text(
              'Start a new basket?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Adding this item will clear your current cart from "$conflictShopName". You can only order from one shop at a time.',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<CartBloc>().add(const ClearCartConflictEvent());
              Navigator.pop(ctx);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CartBloc>().add(ClearAndAddEvent(pendingProduct));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cart replaced with new store item!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.shop.accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Clear Cart & Add',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listenWhen: (prev, curr) =>
          curr.pendingProduct != null && prev.pendingProduct != curr.pendingProduct,
      listener: (context, state) {
        if (state.pendingProduct != null) {
          _showConflictDialog(context, state.pendingProduct!, state.conflictShopName ?? 'Previous Shop');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF9),
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeaderSection(),
                _buildSearchBox(),
                _buildCategoryTabBar(),
                _buildProductListing(),
                // Padding bottom to avoid overlay cover from Floating Cart CTA
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
            _buildFloatingCartButton(),
          ],
        ),
      ),
    );
  }

  // ─── HEADER SECTION ─────────────────────────────────────────────────────────
  Widget _buildHeaderSection() {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return SliverToBoxAdapter(
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: widget.shop.accentColor.withOpacity(0.08),
        ),
        child: Stack(
          children: [
            // Decorative background banner gradient
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.shop.accentColor.withOpacity(0.4),
                    widget.shop.accentColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  widget.shop.imageEmoji,
                  style: const TextStyle(fontSize: 84),
                ),
              ),
            ),
            // Floating overlay shop detail card
            Positioned(
              left: 16,
              right: 16,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.shop.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        // Rating badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 14),
                              const SizedBox(width: 2),
                              Text(
                                widget.shop.rating.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.shop.category} Shop • Verified Partner',
                      style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _detailItem(Icons.location_on_rounded, widget.shop.distance, 'Distance'),
                        _detailItem(Icons.access_time_rounded, widget.shop.deliveryTime, 'Delivery'),
                        _detailItem(
                          Icons.delivery_dining_rounded,
                          widget.shop.deliveryFee,
                          'Fee',
                          color: widget.shop.deliveryFee == 'Free' ? const Color(0xFF006E2F) : Colors.black54,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Custom Back button
            Positioned(
              top: statusBarHeight + 10,
              left: 16,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String value, String label, {Color color = Colors.black54}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black38)),
      ],
    );
  }

  // ─── SEARCH BOX ─────────────────────────────────────────────────────────────
  Widget _buildSearchBox() {
    return SliverToBoxAdapter(
      child: Container(
        color: const Color(0xFFF8FAF9),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _searchCtrl,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search products in this store...',
              hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.black38),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.black45),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  // ─── CATEGORY TABBAR ────────────────────────────────────────────────────────
  Widget _buildCategoryTabBar() {
    if (_tabController == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        child: Container(
          color: const Color(0xFFF8FAF9),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                physics: const BouncingScrollPhysics(),
                indicatorColor: widget.shop.accentColor,
                labelColor: widget.shop.accentColor,
                unselectedLabelColor: Colors.black45,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                tabs: _categories.map((c) => Tab(text: c)).toList(),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── PRODUCT LISTING ────────────────────────────────────────────────────────
  Widget _buildProductListing() {
    if (_isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    final prods = _filteredProducts;
    if (prods.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: Colors.black26),
              SizedBox(height: 8),
              Text('No products match your criteria', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildProductCard(prods[index]),
          childCount: prods.length,
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        final int cartIndex = cartState.items.indexWhere((item) => item.product.id == product.id);
        final int quantity = cartIndex >= 0 ? cartState.items[cartIndex].quantity : 0;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product visual box
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: widget.shop.accentColor.withOpacity(0.04),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Center(
                    child: Text(
                      product.imageUrl, // Emoji placeholder
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.unit,
                      style: const TextStyle(fontSize: 11, color: Colors.black38, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rs. ${product.price}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: widget.shop.accentColor,
                          ),
                        ),
                        // Add/Remove interactive logic
                        quantity > 0
                            ? Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      context.read<CartBloc>().add(UpdateQuantityEvent(product.id, quantity - 1));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: widget.shop.accentColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.remove, size: 14, color: widget.shop.accentColor),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    quantity.toString(),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      context.read<CartBloc>().add(UpdateQuantityEvent(product.id, quantity + 1));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: widget.shop.accentColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.add, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ],
                              )
                            : GestureDetector(
                                onTap: () {
                                  context.read<CartBloc>().add(AddToCartEvent(product));
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: widget.shop.accentColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.shop.accentColor.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.add_shopping_cart_rounded, size: 14, color: Colors.white),
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── FLOATING VIEW CART OVERLAY ─────────────────────────────────────────────
  Widget _buildFloatingCartButton() {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        if (cartState.totalItemCount == 0) return const SizedBox.shrink();

        return Positioned(
          left: 16,
          right: 16,
          bottom: 20,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.shop.accentColor, widget.shop.accentColor.withOpacity(0.85)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: widget.shop.accentColor.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CheckoutScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Items indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${cartState.totalItemCount} items',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Subtotal
                      Text(
                        'Rs. ${cartState.subtotal}',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const Spacer(),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Cart',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                        ],
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

// Delegate for header persistent segment
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate({required this.child});

  @override
  double get minExtent => 50;
  @override
  double get maxExtent => 50;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

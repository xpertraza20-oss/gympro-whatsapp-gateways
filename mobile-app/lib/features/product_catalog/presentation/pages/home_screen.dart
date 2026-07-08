import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../../../auth/presentation/bloc/phone_auth_bloc.dart';
import '../../../auth/presentation/pages/phone_input_screen.dart';
import '../widgets/product_card_widget.dart';
import 'package:grocery_app/features/product_catalog/domain/entities/category.dart';
import 'package:grocery_app/features/product_catalog/domain/usecases/get_categories_usecase.dart';
import 'package:grocery_app/features/product_catalog/domain/repositories/product_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchKeyword = '';
  int? _selectedCategoryId;
  List<Category> _categories = [];
  bool _categoriesLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadCategories();
    _searchController.addListener(_onSearchChanged);
    // Initial fetch
    _triggerFetch(isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _loadCategories() {
    if (!mounted) return;
    setState(() => _categoriesLoading = true);
    final repo = RepositoryProvider.of<ProductRepository>(context);
    GetCategoriesUseCase(repo).call().then((cats) {
      if (mounted) {
        setState(() {
          _categories = cats;
          _categoriesLoading = false;
        });
      }
    }).catchError((err) {
      if (mounted) {
        setState(() => _categoriesLoading = false);
        print("Categories load failed: $err");
      }
    });
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final keyword = _searchController.text.trim();
      if (_searchKeyword != keyword) {
        _searchKeyword = keyword;
        _triggerFetch(isRefresh: true);
      }
    });
  }

  void _triggerFetch({bool isRefresh = false}) {
    context.read<ProductBloc>().add(FetchProductsEvent(
      isRefresh: isRefresh,
      search: _searchKeyword.isNotEmpty ? _searchKeyword : null,
      categoryId: _selectedCategoryId,
    ));
  }

  void _onScroll() {
    if (_isNearBottom) {
      final state = context.read<ProductBloc>().state;
      if (state is ProductLoaded && !state.hasReachedMax && !state.isPaginationLoading) {
        context.read<ProductBloc>().add(FetchProductsEvent(
          isRefresh: false,
          search: _searchKeyword.isNotEmpty ? _searchKeyword : null,
          categoryId: _selectedCategoryId,
        ));
      }
    }
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    // Triggers when scroll reaches 80% of the viewport length (infinite scroll pagination)
    return currentScroll >= (maxScroll * 0.8);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'FreshCart Catalog',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
            ),
            Text(
              'Infinite Scroll & Clean Architecture',
              style: TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () {
              context.read<PhoneAuthBloc>().add(LogoutEvent());
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocListener<PhoneAuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthInitial) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const PhoneInputScreen()),
              (route) => false,
            );
          }
        },
        child: RefreshIndicator(
          onRefresh: () async {
            _loadCategories();
            _triggerFetch(isRefresh: true);
          },
          color: const Color(0xFF10B981),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Sticky/Nice Header / Search Bar area
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search fresh groceries...',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF10B981)),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Categories Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Shop by Category',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937), // Slate-800
                            ),
                          ),
                          if (_categoriesLoading)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              // Horizontal Category Chips
              SliverToBoxAdapter(
                child: Container(
                  height: 50,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length + 1,
                    itemBuilder: (context, index) {
                      // First chip is "All Items"
                      final isAll = index == 0;
                      final isSelected = isAll 
                          ? _selectedCategoryId == null 
                          : _selectedCategoryId == _categories[index - 1].id;
                      final label = isAll ? 'All' : _categories[index - 1].name;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isAll) {
                                _selectedCategoryId = null;
                              } else {
                                final tappedId = _categories[index - 1].id;
                                if (_selectedCategoryId == tappedId) {
                                  _selectedCategoryId = null; // Toggle off
                                } else {
                                  _selectedCategoryId = tappedId;
                                }
                              }
                            });
                            _triggerFetch(isRefresh: true);
                          },
                          borderRadius: BorderRadius.circular(25),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFF10B981) 
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: isSelected 
                                    ? Colors.transparent 
                                    : Colors.grey.shade200,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Product Catalog Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    _selectedCategoryId == null 
                        ? 'All Fresh Products' 
                        : _categories.any((c) => c.id == _selectedCategoryId)
                            ? '${_categories.firstWhere((c) => c.id == _selectedCategoryId).name} Category'
                            : 'Products',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ),

              // SliverGrid of Products
              BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  if (state is ProductLoading) {
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildSkeletonCard(),
                          childCount: 4,
                        ),
                      ),
                    );
                  }

                  if (state is ProductError) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              Text('Failed to load products: ${state.message}'),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => _triggerFetch(isRefresh: true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  if (state is ProductLoaded) {
                    final products = state.products;

                    if (products.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(60.0),
                            child: Text(
                              'No products found matching your search.',
                              style: TextStyle(color: Colors.grey, fontSize: 15),
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= products.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return ProductCardWidget(
                              product: products[index],
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added ${products[index].title} to cart'),
                                    duration: const Duration(milliseconds: 600),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: const Color(0xFF10B981),
                                  ),
                                );
                              },
                            );
                          },
                          // Show trailing pagination loader card if loading nextPage
                          childCount: products.length + (state.isPaginationLoading ? 1 : 0),
                        ),
                      ),
                    );
                  }

                  return const SliverToBoxAdapter(
                    child: SizedBox(),
                  );
                },
              ),

              // Spacer for bottom of list
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 10,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 16,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    height: 24,
                    width: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

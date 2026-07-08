import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../../../auth/presentation/bloc/phone_auth_bloc.dart';
import '../../../auth/presentation/pages/phone_input_screen.dart';
import '../widgets/product_card_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Initial fetch
    context.read<ProductBloc>().add(const FetchProductsEvent());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isNearBottom) {
      context.read<ProductBloc>().add(const FetchProductsEvent());
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
            context.read<ProductBloc>().add(const FetchProductsEvent(isRefresh: true));
          },
          color: const Color(0xFF10B981),
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              if (state is ProductLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF10B981)),
                );
              }

            if (state is ProductError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load products',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<ProductBloc>().add(const FetchProductsEvent(isRefresh: true));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is ProductLoaded) {
              final products = state.products;

              if (products.isEmpty) {
                return const Center(
                  child: Text('No products available.'),
                );
              }

              return Column(
                children: [
                  // Metric / Category quick view ribbon
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: const Color(0xFF10B981).withOpacity(0.05),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Loaded ${products.length} Products',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        if (state.hasReachedMax)
                          const Text(
                            'All Items Loaded',
                            style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600),
                          )
                        else
                          const Text(
                            'Scroll down for more',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  
                  // Product Grid
                  Expanded(
                    child: GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: products.length + (state.isPaginationLoading ? 2 : 0),
                      itemBuilder: (context, index) {
                        // Check if we need to render loading skeleton cards at the bottom
                        if (index >= products.length) {
                          return _buildSkeletonCard();
                        }
                        
                        final product = products[index];
                        return ProductCardWidget(
                          product: product,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Tapped ${product.title}'),
                                duration: const Duration(milliseconds: 600),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            }

            return const Center(
              child: Text('Pull down to load catalog.'),
            );
          },
        ),
      ),
    ),
  );
}

  Widget _buildSkeletonCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 12, width: 100, color: Colors.grey[200]),
            const SizedBox(height: 6),
            Container(height: 10, width: 60, color: Colors.grey[200]),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(height: 14, width: 40, color: Colors.grey[200]),
                Container(height: 24, width: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

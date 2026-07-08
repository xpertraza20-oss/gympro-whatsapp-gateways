import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../../../checkout/presentation/pages/checkout_screen.dart';

class CartBottomSheet extends StatelessWidget {
  const CartBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        final items = state.items;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pull Handler
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Cart',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${state.totalItemCount} items selected',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      if (items.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            context.read<CartBloc>().add(const ClearCartEvent());
                          },
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          label: const Text(
                            'Clear All',
                            style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),

                // Cart Items List
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'Your cart is empty',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Browse fresh groceries and add items to your cart.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final product = item.product;

                        return Row(
                          children: [
                            // Product Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: product.imageUrl,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                memCacheWidth: 150,
                                memCacheHeight: 150,
                                placeholder: (context, url) => Container(color: Colors.grey.shade100),
                                errorWidget: (context, url, err) => Container(
                                  color: Colors.grey.shade100,
                                  child: const Icon(Icons.image_not_supported_outlined, size: 20, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    product.unit,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '\$${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Quantity Selector
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 16),
                                    onPressed: () {
                                      context.read<CartBloc>().add(
                                            UpdateQuantityEvent(product.id, item.quantity - 1),
                                          );
                                    },
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 16),
                                    onPressed: () {
                                      context.read<CartBloc>().add(
                                            UpdateQuantityEvent(product.id, item.quantity + 1),
                                          );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                // Invoice subtotal details card & checkout button
                if (items.isNotEmpty) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Subtotal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                            Text(
                              '\$${state.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                             onPressed: () {
                              Navigator.pop(context); // Close bottom sheet
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CheckoutScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Proceed to Checkout',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

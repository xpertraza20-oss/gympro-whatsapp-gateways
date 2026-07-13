import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:grocery_app/holmon/constants/assets.dart';
import 'package:grocery_app/features/product_catalog/domain/entities/product.dart';
import 'package:grocery_app/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:grocery_app/features/cart/presentation/bloc/cart_event.dart';
import 'package:grocery_app/features/cart/presentation/bloc/cart_state.dart';
import 'package:grocery_app/holmon/utils/wishlist_manager.dart';
import 'package:grocery_app/features/cart/domain/entities/cart_item.dart' as original_cart;

class VegetableCardWidget extends StatelessWidget {
  final Product product;
  const VegetableCardWidget({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final displayPrice = "Rs. ${product.price.toStringAsFixed(0)}";
    final displayRegularPrice = "Rs. ${(product.price * 1.25).toStringAsFixed(0)}";
    const discount = "20%";

    return Container(
      width: (MediaQuery.of(context).size.width / 2) - 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.04), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Core Card Contents
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Center Product Image Container
                  Center(
                    child: GestureDetector(
                      onTap: () => Get.toNamed('/details', arguments: product),
                      child: Hero(
                        tag: "product_image_${product.id}",
                        child: Container(
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.01),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            placeholder: (context, url) => Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryColor.withOpacity(0.5),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              Assets.imagesDish,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Category tag
                  Text(
                    product.category.toUpperCase(),
                    style: TextStyle(
                      color: primaryColor.withOpacity(0.8),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Product Title
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Unit details
                  Text(
                    product.unit,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Pricing Layout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayRegularPrice,
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade400,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            displayPrice,
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      
                      // Dynamic Add to Cart Actions
                      BlocBuilder<CartBloc, CartState>(
                        builder: (context, state) {
                          final cartItem = state.items.firstWhereOrNull((item) => item.product.id == product.id);
                          return cartItem != null
                              ? _buildCartActions(context, cartItem, primaryColor)
                              : _buildCartNoActions(context, primaryColor);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Top Left Premium Discount Badge
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_offer_rounded, size: 10, color: primaryColor),
                    const SizedBox(width: 3),
                    Text(
                      "$discount OFF",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top Right Translucent Heart Wishlist Button
            Positioned(
              top: 10,
              right: 10,
              child: StatefulBuilder(
                builder: (context, setCardState) {
                  final isLiked = WishlistManager.instance.isLiked(product.id.toString());
                  return GestureDetector(
                    onTap: () async {
                      await WishlistManager.instance.toggleLike(product.id.toString());
                      setCardState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Icon(
                        isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isLiked ? Colors.redAccent : Colors.grey.shade400,
                        size: 16,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartActions(BuildContext context, original_cart.CartItem cartItem, Color primaryColor) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.15), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (cartItem.quantity > 1) {
                context.read<CartBloc>().add(UpdateQuantityEvent(product.id, cartItem.quantity - 1));
              } else {
                context.read<CartBloc>().add(RemoveFromCartEvent(product.id));
              }
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.remove, size: 12, color: primaryColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              cartItem.quantity.toString(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              context.read<CartBloc>().add(AddToCartEvent(product));
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartNoActions(BuildContext context, Color primaryColor) {
    return GestureDetector(
      onTap: () {
        context.read<CartBloc>().add(AddToCartEvent(product));
      },
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_shopping_cart_rounded,
          color: Colors.white,
          size: 14,
        ),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:grocery_app/holmon/constants/assets.dart';
import 'package:grocery_app/features/cart/domain/entities/cart_item.dart' as original_cart;
import 'package:grocery_app/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:grocery_app/features/cart/presentation/bloc/cart_event.dart';

class CartItemWidget extends StatelessWidget {
  final original_cart.CartItem item;
  const CartItemWidget({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final displayPrice = "Rs. ${product.price.toStringAsFixed(2)}";

    return InkWell(
      onTap: () async {
        Get.toNamed('/details', arguments: product);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: Container(
              height: 60,
              width: 60,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xffE9F5FA)),
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(50)),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  width: 40,
                  height: 40,
                  filterQuality: FilterQuality.none,
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            )),
            const SizedBox(
              width: 8,
            ),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                        overflow: TextOverflow.ellipsis,
                        fontSize: 14,
                        fontWeight: FontWeight.normal),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text("$displayPrice / ${product.unit}",
                      style: const TextStyle(
                          color: Color(0xffFF324B),
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: const Color(0xffE9F5FA),
                    borderRadius: BorderRadius.circular(24)),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        context.read<CartBloc>().add(AddToCartEvent(product));
                      },
                      child: Image.asset(
                        Assets.imagesAddIcon,
                        width: 28,
                        height: 28,
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Text(
                      item.quantity.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    InkWell(
                      onTap: () {
                        if (item.quantity > 1) {
                          context.read<CartBloc>().add(UpdateQuantityEvent(product.id, item.quantity - 1));
                        } else {
                          context.read<CartBloc>().add(RemoveFromCartEvent(product.id));
                        }
                      },
                      child: Image.asset(
                        Assets.imagesRemoveIcon,
                        width: 28,
                        height: 28,
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

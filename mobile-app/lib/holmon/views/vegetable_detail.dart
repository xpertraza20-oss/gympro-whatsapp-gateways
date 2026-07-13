import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:grocery_app/holmon/constants/assets.dart';
import 'package:grocery_app/features/product_catalog/domain/entities/product.dart';
import 'package:grocery_app/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:grocery_app/features/cart/presentation/bloc/cart_event.dart';
import 'package:grocery_app/features/cart/presentation/bloc/cart_state.dart';
import 'package:grocery_app/features/cart/domain/entities/cart_item.dart' as original_cart;
import 'package:grocery_app/holmon/views/common_widgets/appBar.dart';
import 'package:grocery_app/holmon/views/common_widgets/search_text_field.dart';
import 'package:grocery_app/holmon/utils/wishlist_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'common_widgets/item_key_points_view.dart';

class VegetableDetailScreen extends StatefulWidget {
  const VegetableDetailScreen({Key? key}) : super(key: key);

  @override
  State<VegetableDetailScreen> createState() => _VegetableDetailScreenState();
}

class _VegetableDetailScreenState extends State<VegetableDetailScreen> {
  final Product product = Get.arguments;
  late final List<CachedNetworkImageProvider> multiImageProvider;

  @override
  void initState() {
    super.initState();
    multiImageProvider = [
      CachedNetworkImageProvider(product.imageUrl),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final displayPrice = "Rs. ${product.price.toStringAsFixed(2)}";
    const primaryColor = Color(0xFF006E2F);

    return Scaffold(
      appBar: MyAppBar(
          title: const SearchTextField(
            hint: "What are u looking for ?",
            readOnly: true,
          ),
          leading: InkResponse(onTap: () => Get.back(), child: const BackButtonIcon()),
          actions: <Widget>[
            StatefulBuilder(
              builder: (context, setDetailHeartState) {
                final isLiked = WishlistManager.instance.isLiked(product.id.toString());
                return IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isLiked ? Colors.redAccent : Colors.grey.shade600,
                  ),
                  onPressed: () async {
                    await WishlistManager.instance.toggleLike(product.id.toString());
                    setDetailHeartState(() {});
                  },
                );
              },
            ),
            const SizedBox(width: 8),
          ]),
      
      // Auto-adjusting body utilizing Scaffold height naturally
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkResponse(
                onTap: () {
                  Get.to(() => PhotoViewGallery.builder(
                        scrollPhysics: const BouncingScrollPhysics(),
                        builder: (BuildContext context, int index) {
                          return PhotoViewGalleryPageOptions(
                            maxScale: PhotoViewComputedScale.covered * 1.1,
                            minScale: PhotoViewComputedScale.contained * 0.8,
                            imageProvider: multiImageProvider[index],
                            initialScale: PhotoViewComputedScale.contained * 0.8,
                            heroAttributes: PhotoViewHeroAttributes(tag: product.id),
                          );
                        },
                        itemCount: multiImageProvider.length,
                        pageController: PageController(initialPage: 0),
                      ));
                },
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                          bottom: BorderSide(width: 4, color: primaryColor),
                          left: BorderSide(width: 4, color: primaryColor),
                          right: BorderSide(width: 4, color: primaryColor)),
                      borderRadius: BorderRadius.vertical(
                          bottom: Radius.elliptical(
                              MediaQuery.of(context).size.width, 140.0))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Hero(
                      tag: product.id,
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        width: 140,
                        height: 180,
                        filterQuality: FilterQuality.low,
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$displayPrice / ${product.unit}",
                      style: const TextStyle(
                        color: Color(0xffFF324B),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    Text(
                      "Quantity : ${product.unit}",
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    Text(
                      "Premium Quality Organic product, sourced directly from local partners.",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    Row(
                      children: [
                        ItemKeyPointsView(
                            imagePath: Assets.imagesOrganic,
                            title: "100%",
                            desc: "Organic"),
                        const SizedBox(
                          width: 8,
                        ),
                        ItemKeyPointsView(
                            imagePath: Assets.imagesHouse,
                            title: "Fresh",
                            desc: "Expiration")
                      ],
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        ItemKeyPointsView(
                            imagePath: Assets.imagesReviews,
                            title: "4.8",
                            desc: "Reviews"),
                        const SizedBox(
                          width: 8,
                        ),
                        ItemKeyPointsView(
                            imagePath: Assets.imagesCalories,
                            title: "80 kcal",
                            desc: product.unit)
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, -2),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total price",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      )),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(displayPrice,
                      style: const TextStyle(
                          fontSize: 18,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold))
                ],
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: BlocBuilder<CartBloc, CartState>(
                  builder: (context, state) {
                    final cartItem = state.items.firstWhereOrNull((item) => item.product.id == product.id);
                    return cartItem != null
                        ? _buildCartActions(context, cartItem)
                        : _buildCartNoActions(context);
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartNoActions(BuildContext context) {
    const primaryColor = Color(0xFF006E2F);
    return ElevatedButton(
      onPressed: () {
        context.read<CartBloc>().add(AddToCartEvent(product));
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      child: const Text("Add to cart"),
    );
  }

  Widget _buildCartActions(BuildContext context, original_cart.CartItem cartItem) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkResponse(
          onTap: () {
            context.read<CartBloc>().add(AddToCartEvent(product));
          },
          child: Image.asset(
            Assets.imagesAddIcon,
            width: 40,
            height: 40,
          ),
        ),
        const SizedBox(width: 20),
        Text(
          (cartItem.quantity).toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 20),
        InkResponse(
          onTap: () {
            if (cartItem.quantity > 1) {
              context.read<CartBloc>().add(UpdateQuantityEvent(product.id, cartItem.quantity - 1));
            } else {
              context.read<CartBloc>().add(RemoveFromCartEvent(product.id));
            }
          },
          child: Image.asset(
            Assets.imagesRemoveIcon,
            width: 40,
            height: 40,
          ),
        ),
      ],
    );
  }
}

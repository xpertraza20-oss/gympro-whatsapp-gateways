import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:grocery_app/holmon/constants/assets.dart';
import 'package:grocery_app/holmon/views/common_widgets/appBar.dart';
import 'package:grocery_app/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:grocery_app/features/cart/presentation/bloc/cart_state.dart';
import 'package:grocery_app/features/checkout/presentation/pages/checkout_screen.dart';
import 'common_widgets/cart_item.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyAppBar(
        title: Text(
          "Cart 🛒",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          final cartItemList = state.items;
          if (cartItemList.isEmpty) {
            return Center(
              child: Image.asset(
                Assets.imagesEmptyCart,
                width: 300,
                height: 300,
                filterQuality: FilterQuality.none,
              ),
            );
          }

          final totalCost = state.subtotal;

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 1,
                        child: ListView.separated(
                          scrollDirection: Axis.vertical,
                          separatorBuilder: (context, index) {
                            return const Divider(
                              color: Color(0xffF1F1F5),
                            );
                          },
                          itemCount: cartItemList.length,
                          itemBuilder: (context, index) {
                            return CartItemWidget(
                              item: cartItemList[index],
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(
                          child: Text(
                            "Your shopping cart will remain saved for the next 72 hours and we will send you a notification to complete your purchase.",
                            style: TextStyle(
                                fontSize: 12,
                                color: Get.theme.colorScheme.primary),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 0,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Get.theme.cardColor.withOpacity(0.6),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                            "Add more items to meet the 1200da min order value",
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Get.theme.bottomNavigationBarTheme
                                    .backgroundColor)),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Total price (with tax)",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  )),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                  "Rs. ${totalCost.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (cartItemList.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CheckoutScreen(),
                                    ),
                                  );
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500),
                                shape: const StadiumBorder(),
                                backgroundColor: cartItemList.isNotEmpty
                                    ? Get.theme.primaryColor
                                    : Get.theme.disabledColor,
                              ),
                              child: const Text(
                                "Checkout",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

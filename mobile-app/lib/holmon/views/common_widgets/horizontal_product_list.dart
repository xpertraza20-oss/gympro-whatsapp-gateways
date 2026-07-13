import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/holmon/constants/assets.dart';
import 'package:grocery_app/features/product_catalog/domain/entities/product.dart';
import 'package:grocery_app/features/product_catalog/presentation/bloc/product_bloc.dart';
import 'package:grocery_app/features/product_catalog/presentation/bloc/product_state.dart';
import 'package:grocery_app/features/product_catalog/presentation/bloc/product_event.dart';
import 'package:grocery_app/holmon/views/common_widgets/vegetable_card.dart';

class HorizontalProductList extends StatefulWidget {
  final int page;
  final bool isSecondList;
  const HorizontalProductList({
    Key? key,
    required this.page,
    required this.isSecondList,
  }) : super(key: key);

  @override
  State<HorizontalProductList> createState() => _HorizontalProductListState();
}

class _HorizontalProductListState extends State<HorizontalProductList> {
  @override
  Widget build(BuildContext context) {
    final staticWidget = ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 6,
      itemBuilder: (context, index) {
        return Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 234, 234, 234),
                border: Border.all(color: const Color(0xffF1F1F5)),
                borderRadius: BorderRadius.circular(8),
              ),
              width: (MediaQuery.of(context).size.width / 2) - 34,
            ),
            const SizedBox(width: 8),
          ],
        );
      },
    );

    return RepaintBoundary(
      child: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading || state is ProductInitial) {
            return staticWidget;
          } else if (state is ProductLoaded) {
            List<Product> productList = state.products;
            if (widget.isSecondList) {
              productList = productList.reversed.toList();
            }
            if (productList.isEmpty) {
              return const Center(child: Text("No products found"));
            }
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: productList.length,
              itemBuilder: (context, index) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        VegetableCardWidget(
                          product: productList[index],
                        ),
                        const SizedBox(
                          width: 8,
                        )
                      ],
                    ),
                  ],
                );
              },
            );
          } else if (state is ProductError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    Assets.imagesEmptyList,
                    scale: 4,
                  ),
                  const SizedBox(height: 8),
                  Text(state.message),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ProductBloc>().add(const FetchProductsEvent(isRefresh: true));
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      shape: const StadiumBorder(),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: const Text(
                      "Refresh",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            );
          } else {
            return staticWidget;
          }
        },
      ),
    );
  }
}

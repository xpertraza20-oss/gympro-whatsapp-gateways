import 'package:grocery_app/holmon/constants/assets.dart';
import 'package:grocery_app/holmon/views/common_widgets/appBar.dart';
import 'package:grocery_app/holmon/views/common_widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:grocery_app/features/product_catalog/presentation/bloc/product_bloc.dart';
import 'package:grocery_app/features/product_catalog/presentation/bloc/product_state.dart';
import 'package:grocery_app/features/product_catalog/presentation/bloc/product_event.dart';
import 'package:grocery_app/holmon/views/common_widgets/search_text_field.dart';
import 'common_widgets/vegetable_card.dart';

class VegetablesScreen extends StatefulWidget {
  const VegetablesScreen({Key? key}) : super(key: key);

  @override
  State<VegetablesScreen> createState() => _VegetablesScreenState();
}

class _VegetablesScreenState extends State<VegetablesScreen> {
  final ScrollController _scrollController = ScrollController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final int? argCategoryId = Get.arguments as int?;
    context.read<ProductBloc>().add(FetchProductsEvent(isRefresh: true, categoryId: argCategoryId));
    Future.delayed(const Duration(milliseconds: 340), () {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= (maxScroll * 0.8)) {
      final state = context.read<ProductBloc>().state;
      if (state is ProductLoaded && !state.hasReachedMax && !state.isPaginationLoading) {
        final int? argCategoryId = Get.arguments as int?;
        context.read<ProductBloc>().add(FetchProductsEvent(isRefresh: false, categoryId: argCategoryId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
          title: const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: SearchTextField(
              hint: "Search products...",
              readOnly: true,
            ),
          ),
          leading: InkResponse(onTap: () => Get.back(), child: const BackButtonIcon())),
      body: isLoading
          ? LoadingIndicator(width: 34, height: 34)
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  if (state is ProductLoading || state is ProductInitial) {
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                        mainAxisExtent: 225,
                      ),
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                              color: const Color(0xffdddddd),
                              border: Border.all(color: const Color(0xffF1F1F5)),
                              borderRadius: BorderRadius.circular(8)),
                          width: (MediaQuery.of(context).size.width / 2) - 34,
                        );
                      },
                      itemCount: 6,
                    );
                  } else if (state is ProductLoaded) {
                    final productList = state.products;
                    return DefaultTabController(
                      length: 3,
                      child: RefreshIndicator(
                        onRefresh: () async {
                          final int? argCategoryId = Get.arguments as int?;
                          context.read<ProductBloc>().add(FetchProductsEvent(isRefresh: true, categoryId: argCategoryId));
                        },
                        child: GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          controller: _scrollController,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                            mainAxisExtent: 250,
                          ),
                          itemBuilder: (context, index) {
                            if (index < productList.length) {
                              return VegetableCardWidget(
                                product: productList[index],
                              );
                            } else {
                              return const Center(child: CircularProgressIndicator());
                            }
                          },
                          itemCount: productList.length + (state.hasReachedMax ? 0 : 1),
                        ),
                      ),
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
                          const SizedBox(
                            height: 8,
                          ),
                          Text(state.message),
                          const SizedBox(
                            height: 8,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              context.read<ProductBloc>().add(const FetchProductsEvent(isRefresh: true));
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500),
                              shape: const StadiumBorder(),
                              backgroundColor: Get.theme.primaryColor,
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
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
    );
  }
}

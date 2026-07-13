import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/holmon/constants/assets.dart';
import 'package:grocery_app/holmon/utils/dimensions.dart';
import 'package:grocery_app/holmon/views/common_widgets/appBar.dart';
import 'package:grocery_app/holmon/views/common_widgets/search_text_field.dart';
import 'package:grocery_app/holmon/views/common_widgets/vegetable_card.dart';
import 'package:grocery_app/features/product_catalog/domain/entities/product.dart';
import 'package:grocery_app/features/product_catalog/domain/entities/category.dart';
import 'package:grocery_app/features/product_catalog/domain/usecases/get_categories_usecase.dart';
import 'package:grocery_app/features/product_catalog/domain/repositories/product_repository.dart';
import 'package:grocery_app/features/product_catalog/presentation/bloc/product_bloc.dart';
import 'package:grocery_app/features/product_catalog/presentation/bloc/product_state.dart';
import 'package:grocery_app/features/product_catalog/presentation/bloc/product_event.dart';

class Categories extends StatefulWidget {
  const Categories({Key? key}) : super(key: key);

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories>
    with AutomaticKeepAliveClientMixin {
  List<Category> _categoriesList = [];
  bool _categoriesLoading = true;
  int? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    final repo = RepositoryProvider.of<ProductRepository>(context);
    GetCategoriesUseCase(repo).call().then((cats) {
      if (mounted) {
        setState(() {
          _categoriesList = cats;
          _categoriesLoading = false;
          if (cats.isNotEmpty) {
            selectedCategoryId = cats.first.id;
            context.read<ProductBloc>().add(FetchProductsEvent(
              isRefresh: true,
              categoryId: selectedCategoryId,
            ));
          }
        });
      }
    }).catchError((err) {
      if (mounted) {
        setState(() => _categoriesLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: const MyAppBar(
          title: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: SearchTextField(
          hint: 'Vegetables, fruits, dairy...',
          readOnly: true,
        ),
      )),
      body: _categoriesLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Premium Left Category Navigation Sidebar
                Container(
                  width: 105,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(right: BorderSide(color: Colors.black.withOpacity(0.04))),
                  ),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _categoriesList.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      Category category = _categoriesList[index];
                      final isSelected = selectedCategoryId == category.id;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedCategoryId = category.id;
                          });
                          context.read<ProductBloc>().add(FetchProductsEvent(
                            isRefresh: true,
                            categoryId: category.id,
                          ));
                        },
                        child: CategoryItem(
                          title: category.name,
                          icon: category.imageUrl,
                          isSelected: isSelected,
                        ),
                      );
                    },
                  ),
                ),

                // Premium Product Grid Sidebar on Right
                Expanded(
                  child: BlocBuilder<ProductBloc, ProductState>(
                    builder: (context, state) {
                      if (state is ProductLoading || state is ProductInitial) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is ProductLoaded) {
                        final productList = state.products;
                        if (productList.isEmpty) {
                          return const Center(
                            child: Text(
                              "No products in this category",
                              style: TextStyle(color: Colors.black45, fontSize: 13),
                            ),
                          );
                        }
                        return GridView.builder(
                          padding: const EdgeInsets.all(10),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            mainAxisExtent: 240,
                          ),
                          itemCount: productList.length,
                          itemBuilder: (context, index) {
                            final Product product = productList[index];
                            return VegetableCardWidget(product: product);
                          },
                        );
                      } else if (state is ProductError) {
                        return Center(
                          child: Text('Error: ${state.message}'),
                        );
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class CategoryItem extends StatelessWidget {
  final String? title;
  final String? icon;
  final bool isSelected;

  const CategoryItem(
      {Key? key,
      required this.title,
      required this.icon,
      required this.isSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      width: 105,
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isSelected
            ? primaryColor.withOpacity(0.08)
            : Colors.transparent,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 48,
              width: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.black.withOpacity(0.02),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1),
                    blurRadius: 4,
                  )
                ] : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: icon != null && icon!.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: icon!,
                        fit: BoxFit.cover,
                        width: 48,
                        height: 48,
                        errorWidget: (context, url, err) => Image.asset(Assets.imagesDish, fit: BoxFit.cover),
                      )
                    : Image.asset(
                        icon ?? Assets.imagesDish,
                        fit: BoxFit.cover,
                        width: 48,
                        height: 48,
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
              child: Text(
                title ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? primaryColor
                      : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

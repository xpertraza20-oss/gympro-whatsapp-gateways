import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:grocery_app/holmon/constants/assets.dart';
import 'package:grocery_app/holmon/utils/myTheme.dart';
import 'package:grocery_app/holmon/views/common_widgets/appBar.dart';
import 'package:grocery_app/holmon/views/common_widgets/dropDownHomeMenu.dart';
import 'package:grocery_app/features/product_catalog/domain/entities/category.dart';
import 'package:grocery_app/features/product_catalog/domain/usecases/get_categories_usecase.dart';
import 'package:grocery_app/features/product_catalog/domain/repositories/product_repository.dart';
import 'package:grocery_app/holmon/views/common_widgets/horizontal_product_list.dart';
import 'common_widgets/see_all_view.dart';
import 'common_widgets/carousel.dart';
import 'package:grocery_app/holmon/views/search_screen.dart';
import 'package:grocery_app/features/product_catalog/presentation/bloc/product_bloc.dart';
import 'package:grocery_app/features/product_catalog/presentation/bloc/product_event.dart';

class DashboardScreen extends StatefulWidget {
  DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  
  String _customerName = "FreshCart Customer";
  List<Category> _categoriesList = [];
  bool _categoriesLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCustomerName();
    _loadCategories();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductBloc>().add(const FetchProductsEvent(isRefresh: true));
      }
    });
  }

  Future<void> _loadCustomerName() async {
    const storage = FlutterSecureStorage();
    final name = await storage.read(key: 'user_name');
    if (mounted && name != null && name.isNotEmpty) {
      setState(() {
        _customerName = name;
      });
    }
  }

  void _loadCategories() {
    final repo = RepositoryProvider.of<ProductRepository>(context);
    GetCategoriesUseCase(repo).call().then((cats) {
      if (mounted) {
        setState(() {
          _categoriesList = cats;
          _categoriesLoading = false;
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
    const primaryColor = Color(0xFF006E2F);

    return Scaffold(
      appBar: MyAppBar(
          leading: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
            child: DropDownMenu(),
          ),
          leadingWidth: MediaQuery.of(context).size.width * 2 / 4,
          title: Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(
                  width: 12,
                ),
                const Icon(
                  Icons.delivery_dining,
                  color: Colors.redAccent,
                ),
                const SizedBox(
                  width: 4,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Free delivery',
                      style: TextStyle(
                          color: Get.theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          letterSpacing: 0),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    const Text(
                      '2000da +',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ThemeSwitcher(
                clipper: ThemeSwitcherCircleClipper(),
                builder: (context) {
                  return InkResponse(
                    onTap: () async {
                      final themeSwitcher = ThemeSwitcher.of(context);
                      final currentTheme = Theme.of(context);
                      const storage = FlutterSecureStorage();
                      final email = await storage.read(key: 'user_email') ?? 'guest';
                      final isOrganic = currentTheme.primaryColor == AppThemes.organicGreenTheme.primaryColor;
                      final newTheme = isOrganic ? AppThemes.lightTheme1 : AppThemes.organicGreenTheme;
                      final newThemeKey = isOrganic ? 'light_blue' : 'organic_green';

                      await storage.write(key: 'theme_$email', value: newThemeKey);
                      themeSwitcher.changeTheme(
                        theme: newTheme,
                        isReversed: false,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CircleAvatar(
                        child: Image.asset(
                          Assets.imagesUser,
                          scale: 4,
                        ),
                      ),
                    ),
                  );
                }),
          ]),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ProductBloc>().add(const FetchProductsEvent(isRefresh: true));
          _loadCategories();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(children: [
          // Premium Animated Welcome Banner
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, (1 - value) * 15),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryColor, Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome back,",
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _customerName,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Text("👋", style: TextStyle(fontSize: 28)),
                ],
              ),
            ),
          ),

          Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                  textAlignVertical: TextAlignVertical.center,
                  readOnly: true,
                  onTap: () => Get.to(() => const SearchScreen()),
                  decoration: InputDecoration(
                      border: const OutlineInputBorder(
                          borderSide: BorderSide(
                              style: BorderStyle.solid,
                              color: Color.fromARGB(255, 219, 219, 219)),
                          borderRadius: BorderRadius.all(Radius.circular(8))),
                      hintText: "What are u looking for ?",
                      hintStyle: TextStyle(
                          fontSize: 14,
                          color: Get.theme.colorScheme.primary,
                          fontWeight: FontWeight.w500),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      prefixIcon: Icon(
                        CupertinoIcons.search,
                        color: Theme.of(context).primaryColor,
                      ),
                      suffixIcon: InkWell(
                        onTap: () => Get.toNamed("/ArExperience"),
                        child: const Padding(
                          padding: EdgeInsets.fromLTRB(0, 0, 16, 0),
                          child: Icon(
                            CupertinoIcons.camera,
                            color: Color.fromARGB(255, 193, 193, 193),
                          ),
                        ),
                      )))),
          Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              child: Carousel()),
          Column(
            children: [
              const SizedBox(
                height: 16,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SeeAllView(
                    context: context,
                    name: "Categories 📦",
                    onTapAction: () => Get.toNamed("/dashboard", arguments: 1)),
              ),
              const SizedBox(
                height: 16,
              ),
              
              // Dynamic Bento Grid Categories Display
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _categoriesLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: 110,
                        ),
                        itemCount: _categoriesList.length > 8 ? 8 : _categoriesList.length,
                        itemBuilder: (context, index) {
                          final category = _categoriesList[index];
                          return InkWell(
                            onTap: () {
                              Get.toNamed('/vegetables', arguments: category.id);
                            },
                            child: Column(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Theme.of(context).cardColor,
                                  radius: 32,
                                  child: Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(32),
                                      child: category.imageUrl != null && category.imageUrl!.startsWith('http')
                                          ? CachedNetworkImage(
                                              imageUrl: category.imageUrl!,
                                              fit: BoxFit.cover,
                                              width: 50,
                                              height: 50,
                                              errorWidget: (c, u, e) => Image.asset(Assets.imagesDish),
                                            )
                                          : Image.asset(category.imageUrl ?? Assets.imagesDish, fit: BoxFit.cover),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  category.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SeeAllView(
                    context: context,
                    name: "Best deals 🔥",
                    onTapAction: () => Get.toNamed("/vegetables")),
              ),
              const SizedBox(
                height: 12,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Container(
                    height: 245,
                    child: const HorizontalProductList(
                      page: 1,
                      isSecondList: false,
                    )),
              ),
              const SizedBox(
                height: 16,
              ),
            ],
          ),
        ]),
      ),
    ),
  );
  }
}

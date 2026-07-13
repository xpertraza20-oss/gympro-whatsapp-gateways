import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:grocery_app/holmon/views/profile.dart';
import 'package:grocery_app/holmon/views/categories.dart';
import 'package:grocery_app/holmon/views/dashboard.dart';
import 'package:grocery_app/holmon/views/cart.dart';
import 'package:grocery_app/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:grocery_app/features/cart/presentation/bloc/cart_state.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final RxInt _currentIndex = 0.obs;
  late final PageController _pageController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: _currentIndex.value);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ThemeSwitchingArea(
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            _currentIndex.value = index;
          },
          children: [
            DashboardScreen(),
            Categories(),
            CartScreen(),
            Profile(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
  }

  Widget _buildBottomNavigationBar() {
    return Obx(() {
      return BottomNavigationBar(
        currentIndex: _currentIndex.value,
        onTap: (index) {
          _pageController.jumpToPage(index);
        },
        items: [
          _buildBottomNavigationBarItem(
              _currentIndex.value == 0
                  ? Icons.home_rounded
                  : Icons.home_outlined,
              "Home"),
          _buildBottomNavigationBarItem(
              _currentIndex.value == 1
                  ? CupertinoIcons.cube_box_fill
                  : CupertinoIcons.cube_box,
              "Categories"),
          _buildCartNavigationBarItem(),
          _buildBottomNavigationBarItem(
              _currentIndex.value == 3
                  ? Icons.settings
                  : Icons.settings_outlined,
              "Settings"),
        ],
      );
    });
  }

  BottomNavigationBarItem _buildBottomNavigationBarItem(
      IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      label: label,
    );
  }

  BottomNavigationBarItem _buildCartNavigationBarItem() {
    return BottomNavigationBarItem(
      icon: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          final int cartUpdates = state.totalItemCount;

          return cartUpdates > 0
              ? badges.Badge(
                  badgeContent: Text(
                    cartUpdates.toString(),
                    style: TextStyle(color: Colors.white),
                  ),
                  position: badges.BadgePosition.topEnd(top: -10, end: -10),
                  child: Icon(Icons.shopping_cart_rounded),
                )
              : const Icon(Icons.shopping_cart_outlined);
        },
      ),
      label: "Cart",
    );
  }
}

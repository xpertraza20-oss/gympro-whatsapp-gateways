import 'package:get/get.dart';
import 'package:grocery_app/holmon/views/cart.dart';
import 'package:grocery_app/holmon/views/dashboard.dart';
import 'package:grocery_app/holmon/views/home.dart';
import 'package:grocery_app/holmon/views/profile.dart';
import 'package:grocery_app/holmon/views/registration.dart';
import 'package:grocery_app/holmon/views/splash.dart';
import 'package:grocery_app/holmon/views/vegetable_detail.dart';
import 'package:grocery_app/holmon/views/vegetables.dart';
import 'package:grocery_app/holmon/views/welcome.dart';
import 'package:grocery_app/holmon/views/categories.dart';

class MyRoutes {
  static final List<GetPage> pages = [
    GetPage(name: '/splash', page: () => SplashScreen()),
    GetPage(name: '/', page: () => WelcomeScreen()),
    GetPage(name: '/registration', page: () => RegistrationScreen()),
    GetPage(name: '/dashboard', page: () => HomeScreen()),
    GetPage(name: '/home', page: () => DashboardScreen()),
    GetPage(name: '/categories', page: () => Categories()),
    GetPage(name: '/cart', page: () => CartScreen()),
    GetPage(name: '/profile', page: () => Profile()),
    GetPage(name: '/vegetables', page: () => VegetablesScreen()),
    //GetPage(name: '/search', page: () => VegetablesSearchScreen()),
    GetPage(name: '/details', page: () => VegetableDetailScreen()),
    //GetPage(name: '/ArExperience', page: () => ArExperience()),
  ];
}

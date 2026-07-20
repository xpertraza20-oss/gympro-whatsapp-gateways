import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'language_bloc.dart';
import 'language_state.dart';

class AppTranslations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'welcome': 'Welcome',
      'welcome_store': 'WELCOME TO FRESHCART',
      'welcome_desc': 'Get the best organic produce and daily essentials delivered in minutes.',
      'fresh_grocery': 'Fresh Groceries Delivered',
      'tagline': 'Get organic groceries delivered straight to your door step.',
      'start_shopping': 'Start Shopping',
      'select_role': 'Select Your Role',
      'customer': 'Customer',
      'shopkeeper': 'Shopkeeper',
      'rider': 'Rider',
      'continue': 'Continue',
      'customer_desc': 'Order groceries and items from nearby stores.',
      'shopkeeper_desc': 'Manage your store products and incoming orders.',
      'rider_desc': 'Deliver grocery packages and earn money.',
      'change_language': 'اردو میں تبدیل کریں',
      'organic_partners': '100% Organic Partners',
      'delivery_speed': '15-Min Delivery',
      'delivery_speed_desc': 'Hyper-local speeds',
      'farm_fresh': 'Farm Fresh',
      'farm_fresh_desc': 'Direct sourcing',
      'get_started': 'Get Started',
      'sign_up': 'Sign Up',
      'sign_in': 'Sign In',
      'secure_delivery': 'Secure contactless delivery guaranteed',
      'choose_role': 'Choose Your Role',
      'role_tagline': 'Select how you want to use the app.',
      'data_secure': 'Your data is safe and secure with us.',
      'shopkeeper_title': 'Shopkeeper / Business',
      'onboarding_subtitle': 'Your Grocery,\nFast and Safe Delivery',
      'select_language': 'Select Language / زبان منتخب کریں',
      'continue_button': 'Continue',
    },
    'ur': {
      'welcome': 'خوش آمدید',
      'welcome_store': 'فریش کارٹ میں خوش آمدید',
      'welcome_desc': 'تازہ ترین سبزیاں، پھل اور روزمرہ کی ضروریات منٹوں میں حاصل کریں۔',
      'fresh_grocery': 'تازہ راشن کی ہوم ڈلیوری',
      'tagline': 'تازہ اور نامیاتی اشیاء اب براہِ راست آپ کے دہلیز پر۔',
      'start_shopping': 'خریداری شروع کریں',
      'select_role': 'اپنا کردار منتخب کریں',
      'customer': 'گاہک',
      'shopkeeper': 'دکاندار',
      'rider': 'رائیڈر',
      'continue': 'جاری رکھیں',
      'customer_desc': 'قریبی دکانوں سے راشن اور سودا سلف آرڈر کریں۔',
      'shopkeeper_desc': 'اپنی دکان کی اشیاء اور آنے والے آرڈرز کا انتظام کریں۔',
      'rider_desc': 'آرڈرز کی ترسیل کریں اور منافع کمائیں۔',
      'change_language': 'Change to English',
      'organic_partners': '۱۰۰٪ خالص آرگینک پارٹنرز',
      'delivery_speed': '۱۵ منٹ ترسیل',
      'delivery_speed_desc': 'انتہائی تیز رفتار',
      'farm_fresh': 'فارم سے تازہ',
      'farm_fresh_desc': 'براہِ راست خریداری',
      'get_started': 'شروع کریں',
      'sign_up': 'سائن اپ',
      'sign_in': 'لاگ ان',
      'secure_delivery': 'محفوظ اور بلا رابطہ ترسیل کی ضمانت',
      'choose_role': 'اپنا کردار منتخب کریں',
      'role_tagline': 'منتخب کریں کہ آپ ایپ کو کس طرح استعمال کرنا چاہتے ہیں۔',
      'data_secure': 'آپ کا ڈیٹا ہمارے پاس محفوظ اور مامون ہے۔',
      'shopkeeper_title': 'دکاندار / کاروباری ادارہ',
      'onboarding_subtitle': 'آپ کا راشن،\nتیز اور محفوظ ترسیل',
      'select_language': 'زبان منتخب کریں / Select Language',
      'continue_button': 'جاری رکھیں',
    }
  };

  static String translate(BuildContext context, String key) {
    final languageCode = context.read<LanguageBloc>().state.locale.languageCode;
    return _localizedValues[languageCode]?[key] ?? key;
  }

  // Helper method to automatically apply Jamil Noori Nastaleeq font and spacing adjustments for Urdu
  static TextStyle getTextStyle(BuildContext context, {TextStyle? baseStyle}) {
    final isUrdu = context.read<LanguageBloc>().state.locale.languageCode == 'ur';
    if (isUrdu) {
      final style = baseStyle ?? const TextStyle();
      return style.copyWith(
        fontFamily: 'JamilNooriNastaleeq',
        // Jamil Noori Nastaleeq requires slightly larger height to avoid vertical clipping
        height: style.height != null ? style.height! * 1.4 : 1.5,
        fontSize: style.fontSize != null ? style.fontSize! * 1.12 : 16.0,
      );
    }
    return baseStyle ?? const TextStyle();
  }
}

// Convenient Extension for Widgets to fetch translations and styles inline
extension TranslationExtensions on BuildContext {
  String tr(String key) => AppTranslations.translate(this, key);
  
  bool get isUrdu => BlocProvider.of<LanguageBloc>(this).state.locale.languageCode == 'ur';

  TextDirection get textDirection => isUrdu ? TextDirection.rtl : TextDirection.ltr;

  TextStyle urStyle({TextStyle? style}) => AppTranslations.getTextStyle(this, baseStyle: style);
}

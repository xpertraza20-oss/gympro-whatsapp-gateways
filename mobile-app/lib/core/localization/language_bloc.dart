import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'language_event.dart';
import 'language_state.dart';

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  static const String _languageKey = 'user_selected_language';

  LanguageBloc() : super(LanguageState.initial()) {
    on<ChangeLanguageEvent>(_onChangeLanguage);
    on<LoadSavedLanguageEvent>(_onLoadSavedLanguage);
  }

  Future<void> _onChangeLanguage(
    ChangeLanguageEvent event,
    Emitter<LanguageState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, event.locale.languageCode);
      Get.updateLocale(event.locale);
      emit(LanguageState(locale: event.locale));
    } catch (e) {
      Get.updateLocale(event.locale);
      emit(LanguageState(locale: event.locale));
    }
  }

  Future<void> _onLoadSavedLanguage(
    LoadSavedLanguageEvent event,
    Emitter<LanguageState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);
      if (languageCode != null) {
        final loc = Locale(languageCode);
        Get.updateLocale(loc);
        emit(LanguageState(locale: loc));
      } else {
        emit(LanguageState.initial());
      }
    } catch (e) {
      emit(LanguageState.initial());
    }
  }
}

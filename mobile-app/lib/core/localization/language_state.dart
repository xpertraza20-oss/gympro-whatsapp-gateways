import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class LanguageState extends Equatable {
  final Locale locale;

  const LanguageState({required this.locale});

  factory LanguageState.initial() {
    return const LanguageState(locale: Locale('en'));
  }

  @override
  List<Object?> get props => [locale];
}

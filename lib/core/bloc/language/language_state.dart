import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../services/language_service.dart';
import '../../constants/app_strings_en.dart';

class LanguageState extends Equatable {
  final AppLanguage currentLanguage;
  final Map<String, String> strings;
  final bool isLoading;

  const LanguageState({
    required this.currentLanguage,
    required this.strings,
    this.isLoading = false,
  });

  LanguageState copyWith({
    AppLanguage? currentLanguage,
    Map<String, String>? strings,
    bool? isLoading,
  }) {
    return LanguageState(
      currentLanguage: currentLanguage ?? this.currentLanguage,
      strings: strings ?? this.strings,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => [currentLanguage, strings, isLoading];

  @override
  String toString() =>
      'LanguageState(currentLanguage: $currentLanguage, isLoading: $isLoading)';

  // Helper methods
  String getString(String key) {
    return strings[key] ?? key;
  }

  String getLanguageDisplayName() {
    switch (currentLanguage) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.myanmar:
        return 'မြန်မာ';
      default:
        return 'English';
    }
  }

  String getLanguageCode() {
    switch (currentLanguage) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.myanmar:
        return 'my';
      default:
        return 'en';
    }
  }

  bool get isMyanmarLanguage => currentLanguage == AppLanguage.myanmar;

  bool get isEnglishLanguage => currentLanguage == AppLanguage.english;

  TextDirection getTextDirection() {
    return TextDirection.ltr; // Both English and Myanmar are LTR
  }

  String? getFontFamily() {
    switch (currentLanguage) {
      case AppLanguage.myanmar:
        return 'Myanmar'; // You'll need to add a Myanmar font to pubspec.yaml
      case AppLanguage.english:
        return null; // Use system default
      default:
        return null;
    }
  }
}

class LanguageInitial extends LanguageState {
  LanguageInitial()
    : super(
        currentLanguage: AppLanguage.english,
        strings: AppStringsEn.strings,
        isLoading: true,
      );
}

class LanguageLoading extends LanguageState {
  LanguageLoading({required LanguageState previousState})
    : super(
        currentLanguage: previousState.currentLanguage,
        strings: previousState.strings,
        isLoading: true,
      );
}

class LanguageLoaded extends LanguageState {
  const LanguageLoaded({
    required AppLanguage currentLanguage,
    required Map<String, String> strings,
  }) : super(
         currentLanguage: currentLanguage,
         strings: strings,
         isLoading: false,
       );
}

class LanguageChanged extends LanguageState {
  const LanguageChanged({
    required AppLanguage currentLanguage,
    required Map<String, String> strings,
  }) : super(
         currentLanguage: currentLanguage,
         strings: strings,
         isLoading: false,
       );
}

class LanguageError extends LanguageState {
  final String message;

  LanguageError({required this.message, required LanguageState previousState})
    : super(
        currentLanguage: previousState.currentLanguage,
        strings: previousState.strings,
        isLoading: false,
      );

  @override
  List<Object> get props => [currentLanguage, strings, isLoading, message];
}

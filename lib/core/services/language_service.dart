import 'package:flutter/material.dart';

enum AppLanguage { english, myanmar }

class LanguageService {
  // Helper method to check if text contains Myanmar characters
  static bool containsMyanmar(String text) {
    return RegExp(r'[\u1000-\u109F\uAA60-\uAA7F]').hasMatch(text);
  }

  // Helper method to get appropriate font for mixed text
  static TextStyle getTextStyle(TextStyle style, AppLanguage language) {
    if (language == AppLanguage.myanmar || containsMyanmar(style.toString())) {
      return style.copyWith(fontFamily: 'Myanmar'); // You'll need to add a Myanmar font to pubspec.yaml
    }
    return style;
  }

  // Helper method to get font family based on language
  static String? getFontFamily(AppLanguage language) {
    switch (language) {
      case AppLanguage.myanmar:
        return 'Myanmar'; // You'll need to add a Myanmar font to pubspec.yaml
      case AppLanguage.english:
        return null; // Use system default
      default:
        return null;
    }
  }

  // Helper method to get text direction based on language
  static TextDirection getTextDirection(AppLanguage language) {
    return TextDirection.ltr; // Both English and Myanmar are LTR
  }

  // Helper method to get language display name
  static String getLanguageDisplayName(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.myanmar:
        return 'မြန်မာ';
      default:
        return 'English';
    }
  }

  // Helper method to get language code
  static String getLanguageCode(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.myanmar:
        return 'my';
      default:
        return 'en';
    }
  }

  // Helper method to get language flag emoji
  static String getLanguageFlag(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return '🇬🇧';
      case AppLanguage.myanmar:
        return '🇲🇲';
      default:
        return '🇬🇧';
    }
  }
}
import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_strings_en.dart';
import '../../constants/app_strings_my.dart';
import '../../services/language_service.dart';
import 'language_event.dart';
import 'language_state.dart';

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  static const String _languageKey = 'selected_language';

  LanguageBloc() : super(LanguageInitial()) {
    on<LoadLanguage>(_onLoadLanguage);
    on<ChangeLanguage>(_onChangeLanguage);
  }

  Future<void> _onLoadLanguage(
    LoadLanguage event,
    Emitter<LanguageState> emit,
  ) async {
    try {
      emit(LanguageLoading(previousState: state));

      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);

      AppLanguage language;
      if (languageCode != null) {
        language = AppLanguage.values.firstWhere(
          (lang) => lang.name == languageCode,
          orElse: () => AppLanguage.english,
        );
      } else {
        language = AppLanguage.english;
      }

      final strings = _getStringsForLanguage(language);
      emit(LanguageLoaded(currentLanguage: language, strings: strings));
    } catch (e) {
      emit(
        LanguageError(
          message: 'Failed to load language: $e',
          previousState: state,
        ),
      );
    }
  }

  Future<void> _onChangeLanguage(
    ChangeLanguage event,
    Emitter<LanguageState> emit,
  ) async {
    try {
      // Save to storage first
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, event.language.name);

      // Then emit the new state immediately
      final strings = _getStringsForLanguage(event.language);
      emit(LanguageChanged(currentLanguage: event.language, strings: strings));

      // Also emit LanguageLoaded to ensure all listeners get the update
      emit(LanguageLoaded(currentLanguage: event.language, strings: strings));
    } catch (e) {
      emit(
        LanguageError(
          message: 'Failed to change language: $e',
          previousState: state,
        ),
      );
    }
  }

  Map<String, String> _getStringsForLanguage(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return AppStringsEn.strings;
      case AppLanguage.myanmar:
        return AppStringsMy.strings;
      default:
        return AppStringsEn.strings;
    }
  }

  // Helper methods for easy access
  String getString(String key) {
    return state.getString(key);
  }

  String getLanguageDisplayName() {
    return state.getLanguageDisplayName();
  }

  String getLanguageCode() {
    return state.getLanguageCode();
  }

  bool get isMyanmarLanguage => state.isMyanmarLanguage;

  bool get isEnglishLanguage => state.isEnglishLanguage;

  TextDirection getTextDirection() {
    return state.getTextDirection();
  }

  String? getFontFamily() {
    return state.getFontFamily();
  }
}

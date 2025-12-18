import 'package:equatable/equatable.dart';
import '../../services/language_service.dart';

abstract class LanguageEvent extends Equatable {
  const LanguageEvent();

  @override
  List<Object> get props => [];
}

class LoadLanguage extends LanguageEvent {}

class ChangeLanguage extends LanguageEvent {
  final AppLanguage language;

  const ChangeLanguage(this.language);

  @override
  List<Object> get props => [language];
}
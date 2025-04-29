part of 'user_preferences_bloc.dart';

abstract class UserPreferencesEvent extends Equatable {
  const UserPreferencesEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserPreferences extends UserPreferencesEvent {}

class ChangeThemeMode extends UserPreferencesEvent {
  final ThemeMode themeMode;

  const ChangeThemeMode({required this.themeMode});

  @override
  List<Object?> get props => [themeMode];
}

class ChangeLanguage extends UserPreferencesEvent {
  final String languageCode;

  const ChangeLanguage({required this.languageCode});

  @override
  List<Object?> get props => [languageCode];
}
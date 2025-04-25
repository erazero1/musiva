part of 'theme_bloc.dart';

abstract class ThemeEvent {}

class ToggleThemeEvent extends ThemeEvent {}

class SetThemeModeEvent extends ThemeEvent {
  final ThemeMode themeMode;
  SetThemeModeEvent(this.themeMode);
}
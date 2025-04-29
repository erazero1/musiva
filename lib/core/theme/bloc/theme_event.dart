part of 'theme_bloc.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

class ToggleThemeEvent extends ThemeEvent {}

class SetThemeModeEvent extends ThemeEvent {
  final ThemeMode themeMode;

  const SetThemeModeEvent({required this.themeMode});

  @override
  List<Object?> get props => [themeMode];
}

class InitializeThemeEvent extends ThemeEvent {}

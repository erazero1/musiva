import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeState(themeMode: ThemeMode.system)) {
    on<ToggleThemeEvent>(_onToggleTheme);
    on<SetThemeModeEvent>(_onSetThemeMode);
  }

  void _onToggleTheme(ToggleThemeEvent event, Emitter<ThemeState> emit) {
    final currentMode = state.themeMode;
    late ThemeMode newMode;

    switch (currentMode) {
      case ThemeMode.light:
        newMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        newMode = ThemeMode.system;
        break;
      case ThemeMode.system:
        newMode = ThemeMode.light;
        break;
    }

    emit(state.copyWith(themeMode: newMode));
  }

  void _onSetThemeMode(SetThemeModeEvent event, Emitter<ThemeState> emit) {
    emit(state.copyWith(themeMode: event.themeMode));
  }
}
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:musiva/features/settings/domain/entities/user_preferences.dart';
import 'package:musiva/features/settings/presentation/bloc/user_preferences_bloc.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final UserPreferencesBloc userPreferencesBloc;

  ThemeBloc({required this.userPreferencesBloc})
      : super(const ThemeState(themeMode: ThemeMode.system)) {

    // Register event handlers
    on<ToggleThemeEvent>(_onToggleTheme);
    on<SetThemeModeEvent>(_onSetThemeMode);
    on<InitializeThemeEvent>(_onInitializeTheme);

    // Add initial event to initialize theme from user preferences
    add(InitializeThemeEvent());

    // Listen to user preferences changes
    userPreferencesBloc.stream.listen((state) {
      if (state is UserPreferencesLoaded) {
        // Only update if different from current to avoid infinite loops
        if (this.state.themeMode != state.preferences.themeMode) {
          add(SetThemeModeEvent(themeMode: state.preferences.themeMode));
        }
      }
    });
  }

  void _onToggleTheme(ToggleThemeEvent event, Emitter<ThemeState> emit) {
    final newThemeMode = state.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;

    emit(ThemeState(themeMode: newThemeMode));

    // Update user preferences in Firebase
    userPreferencesBloc.add(ChangeThemeMode(themeMode: newThemeMode));
  }

  void _onSetThemeMode(SetThemeModeEvent event, Emitter<ThemeState> emit) {
    // Only emit if different to prevent unnecessary updates
    if (state.themeMode != event.themeMode) {
      emit(ThemeState(themeMode: event.themeMode));

      // Update user preferences in Firebase
      userPreferencesBloc.add(ChangeThemeMode(themeMode: event.themeMode));
    }
  }

  void _onInitializeTheme(InitializeThemeEvent event, Emitter<ThemeState> emit) {
    // Get theme from user preferences if available
    final preferencesState = userPreferencesBloc.state;
    if (preferencesState is UserPreferencesLoaded) {
      emit(ThemeState(themeMode: preferencesState.preferences.themeMode));
    }
  }
}

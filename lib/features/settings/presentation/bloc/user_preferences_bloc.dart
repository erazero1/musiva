import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:musiva/core/usecases/usecase.dart';
import 'package:musiva/features/settings/domain/entities/user_preferences.dart';
import 'package:musiva/features/settings/domain/usecases/get_user_preferences.dart';
import 'package:musiva/features/settings/domain/usecases/save_user_preferences.dart';

part 'user_preferences_event.dart';
part 'user_preferences_state.dart';

class UserPreferencesBloc extends Bloc<UserPreferencesEvent, UserPreferencesState> {
  final GetUserPreferences getUserPreferences;
  final SaveUserPreferences saveUserPreferences;

  // Track last preferences to prevent redundant saves
  UserPreferences? _lastSavedPreferences;

  UserPreferencesBloc({
    required this.getUserPreferences,
    required this.saveUserPreferences,
  }) : super(UserPreferencesInitial()) {
    on<LoadUserPreferences>(_onLoadUserPreferences);
    on<ChangeThemeMode>(_onChangeThemeMode);
    on<ChangeLanguage>(_onChangeLanguage);
  }

  Future<void> _onLoadUserPreferences(
      LoadUserPreferences event,
      Emitter<UserPreferencesState> emit,
      ) async {
    emit(UserPreferencesLoading());

    final preferencesResult = await getUserPreferences(NoParams());

    await preferencesResult.fold(
          (failure) async => emit(const UserPreferencesError(message: 'Failed to load preferences')),
          (preferences) async {
        _lastSavedPreferences = preferences;
        emit(UserPreferencesLoaded(preferences: preferences));
      },
    );
  }

  Future<void> _onChangeThemeMode(
      ChangeThemeMode event,
      Emitter<UserPreferencesState> emit,
      ) async {
    if (state is UserPreferencesLoaded) {
      final currentState = state as UserPreferencesLoaded;

      // Create updated preferences
      final updatedPreferences = currentState.preferences.copyWith(
        themeMode: event.themeMode,
      );

      // Check if preferences actually changed to avoid redundant saving
      if (_lastSavedPreferences?.themeMode != updatedPreferences.themeMode) {
        emit(UserPreferencesLoaded(preferences: updatedPreferences));

        // Save to Firebase
        final result = await saveUserPreferences(
          SaveUserPreferencesParams(preferences: updatedPreferences),
        );

        result.fold(
              (failure) => emit(UserPreferencesError(
              message: 'Failed to save theme preferences',
              preferences: updatedPreferences)),
              (_) {
            _lastSavedPreferences = updatedPreferences;
          },
        );
      }
    }
  }

  Future<void> _onChangeLanguage(
      ChangeLanguage event,
      Emitter<UserPreferencesState> emit,
      ) async {
    if (state is UserPreferencesLoaded) {
      final currentState = state as UserPreferencesLoaded;

      // Create updated preferences
      final updatedPreferences = currentState.preferences.copyWith(
        languageCode: event.languageCode,
      );

      // Check if preferences actually changed to avoid redundant saving
      if (_lastSavedPreferences?.languageCode != updatedPreferences.languageCode) {
        emit(UserPreferencesLoaded(preferences: updatedPreferences));

        // Save to Firebase
        final result = await saveUserPreferences(
          SaveUserPreferencesParams(preferences: updatedPreferences),
        );

        result.fold(
              (failure) => emit(UserPreferencesError(
              message: 'Failed to save language preferences',
              preferences: updatedPreferences)),
              (_) {
            _lastSavedPreferences = updatedPreferences;
          },
        );
      }
    }
  }
}
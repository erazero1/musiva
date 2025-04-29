part of 'user_preferences_bloc.dart';

abstract class UserPreferencesState extends Equatable {
  const UserPreferencesState();

  @override
  List<Object?> get props => [];
}

class UserPreferencesInitial extends UserPreferencesState {}

class UserPreferencesLoading extends UserPreferencesState {}

class UserPreferencesLoaded extends UserPreferencesState {
  final UserPreferences preferences;

  const UserPreferencesLoaded({required this.preferences});

  @override
  List<Object?> get props => [preferences];
}

class UserPreferencesError extends UserPreferencesState {
  final String message;
  final UserPreferences? preferences;

  const UserPreferencesError({required this.message, this.preferences});

  @override
  List<Object?> get props => [message, preferences];
}
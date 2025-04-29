import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:musiva/core/error/failures.dart';
import 'package:musiva/core/usecases/usecase.dart';
import 'package:musiva/features/settings/domain/entities/user_preferences.dart';
import 'package:musiva/features/settings/domain/repositories/user_preferences_repository.dart';

class SaveUserPreferences implements UseCase<void, SaveUserPreferencesParams> {
  final UserPreferencesRepository repository;

  SaveUserPreferences(this.repository);

  @override
  Future<Either<Failure, void>> call(SaveUserPreferencesParams params) {
    return repository.saveUserPreferences(params.preferences);
  }
}

class SaveUserPreferencesParams extends Equatable {
  final UserPreferences preferences;

  const SaveUserPreferencesParams({required this.preferences});

  @override
  List<Object?> get props => [preferences];
}

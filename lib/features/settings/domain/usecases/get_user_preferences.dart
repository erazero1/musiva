import 'package:dartz/dartz.dart';
import 'package:musiva/core/error/failures.dart';
import 'package:musiva/core/usecases/usecase.dart';
import 'package:musiva/features/settings/domain/entities/user_preferences.dart';
import 'package:musiva/features/settings/domain/repositories/user_preferences_repository.dart';

class GetUserPreferences implements UseCase<UserPreferences, NoParams> {
  final UserPreferencesRepository repository;

  GetUserPreferences(this.repository);

  @override
  Future<Either<Failure, UserPreferences>> call(NoParams params) {
    return repository.getUserPreferences();
  }
}
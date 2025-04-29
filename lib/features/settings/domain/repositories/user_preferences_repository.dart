import 'package:dartz/dartz.dart';
import 'package:musiva/core/error/failures.dart';
import 'package:musiva/features/settings/domain/entities/user_preferences.dart';

abstract class UserPreferencesRepository {
  Future<Either<Failure, UserPreferences>> getUserPreferences();

  Future<Either<Failure, void>> saveUserPreferences(
      UserPreferences preferences);
}

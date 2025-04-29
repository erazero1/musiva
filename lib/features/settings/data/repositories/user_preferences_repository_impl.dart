import 'package:dartz/dartz.dart';
import 'package:musiva/core/error/failures.dart';
import 'package:musiva/features/settings/data/datasources/user_preferences_data_source.dart';
import 'package:musiva/features/settings/domain/entities/user_preferences.dart';
import 'package:musiva/features/settings/domain/repositories/user_preferences_repository.dart';

class UserPreferencesRepositoryImpl implements UserPreferencesRepository {
  final UserPreferencesDataSource dataSource;

  UserPreferencesRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, UserPreferences>> getUserPreferences() async {
    try {
      final preferences = await dataSource.getUserPreferences();
      return Right(preferences);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> saveUserPreferences(
      UserPreferences preferences) async {
    try {
      await dataSource.saveUserPreferences(preferences);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}

import 'package:dartz/dartz.dart';

import '../entities/user.dart';
import '../../../../core/error/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> getCurrentUser();
  Future<Either<Failure, User>> login(String email, String password);
  Future<Either<Failure, User>> register(String email, String password, String? displayName);
  Future<Either<Failure, void>> logout();
  Future<bool> signInAnonymously();
  Future<bool> signInWithGoogle();
  bool isGuest();
}
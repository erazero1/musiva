import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/retry_helper.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final fb_auth.FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.firebaseAuth,
    required this.googleSignIn
  });

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final remoteUser = await remoteDataSource.getCurrentUser();
      await localDataSource.cacheUser(remoteUser);
      return Right(remoteUser);
    } on ServerException catch (e) {
      try {
        // Try to get user from cache if remote fails
        final localUser = await localDataSource.getCachedUser();
        return Right(localUser);
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.login(email, password);
        await localDataSource.cacheUser(user);
        return Right(user);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, User>> register(String email, String password, String? displayName) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.register(email, password, displayName);
        await localDataSource.cacheUser(user);
        return Right(user);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.logout();
        await localDataSource.clearCachedUser();
        await firebaseAuth.signOut();
        await googleSignIn.signOut();
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  bool isGuest() {
    final user = firebaseAuth.currentUser;
    return user != null && user.isAnonymous;
  }

  @override
  Future<bool> signInAnonymously() async {
    try {
      // Use retry mechanism for anonymous sign-in
      await RetryHelper.retry(
        operation: () => firebaseAuth.signInAnonymously(),
        maxRetries: 3,
        retryDelay: 1000,
        // Only retry for network-related errors
        retryIf: (e) => e is fb_auth.FirebaseAuthException && 
                        e.code == 'network-request-failed',
        onRetry: (exception, attempt, maxAttempts) {
          log.w('AuthRepositoryImpl: Retrying anonymous sign-in (attempt $attempt/$maxAttempts) after network error');
        },
      );
      return true;
    } catch (e) {
      log.e('AuthRepositoryImpl: Failed to sign in anonymously', e);
      return false;
    }
  }

  @override
  Future<bool> signInWithGoogle() async {
    try {
      // Google sign-in process with retry mechanism
      final googleUser = await RetryHelper.retry(
        operation: () => googleSignIn.signIn(),
        maxRetries: 3,
        retryDelay: 1000,
        onRetry: (exception, attempt, maxAttempts) {
          log.w('AuthRepositoryImpl: Retrying Google sign-in (attempt $attempt/$maxAttempts) after error');
        },
      );
      
      if (googleUser == null) return false;
      
      // Get authentication tokens with retry
      final googleAuth = await RetryHelper.retry(
        operation: () => googleUser.authentication,
        maxRetries: 3,
        retryDelay: 1000,
        onRetry: (exception, attempt, maxAttempts) {
          log.w('AuthRepositoryImpl: Retrying Google authentication (attempt $attempt/$maxAttempts) after error');
        },
      );

      final credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with credential with retry
      await RetryHelper.retry(
        operation: () => firebaseAuth.signInWithCredential(credential),
        maxRetries: 3,
        retryDelay: 1000,
        // Only retry for network-related errors
        retryIf: (e) => e is fb_auth.FirebaseAuthException && 
                        e.code == 'network-request-failed',
        onRetry: (exception, attempt, maxAttempts) {
          log.w('AuthRepositoryImpl: Retrying Firebase credential sign-in (attempt $attempt/$maxAttempts) after error');
        },
      );
      
      return true;
    } catch (e) {
      log.e('AuthRepositoryImpl: Failed to sign in with Google', e);
      return false;
    }
  }
}
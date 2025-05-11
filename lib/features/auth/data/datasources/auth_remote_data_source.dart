import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/retry_helper.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> getCurrentUser();
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String password, String? displayName);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;
  static const String _tag = 'AuthRemoteDataSource';

  AuthRemoteDataSourceImpl({required this.firebaseAuth});

  @override
  Future<UserModel> getCurrentUser() async {
    final firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser != null) {
      return UserModel.fromFirebaseUser(firebaseUser);
    } else {
      throw ServerException(message: 'No user logged in');
    }
  }

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      // Use retry mechanism for login
      final userCredential = await RetryHelper.retry(
        operation: () => firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
        maxRetries: 3,
        retryDelay: 1000,
        // Only retry for network-related errors
        retryIf: (e) => e is firebase_auth.FirebaseAuthException && 
                        e.code == 'network-request-failed',
        onRetry: (exception, attempt, maxAttempts) {
          log.w('$_tag: Retrying login (attempt $attempt/$maxAttempts) after network error');
        },
      );

      if (userCredential.user != null) {
        return UserModel.fromFirebaseUser(userCredential.user!);
      } else {
        throw ServerException(message: 'Login failed');
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(message: e.message ?? 'Authentication failed');
    }
  }

  @override
  Future<UserModel> register(String email, String password, String? displayName) async {
    try {
      // Use retry mechanism for registration
      final userCredential = await RetryHelper.retry(
        operation: () => firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
        maxRetries: 3,
        retryDelay: 1000,
        // Only retry for network-related errors
        retryIf: (e) => e is firebase_auth.FirebaseAuthException && 
                        e.code == 'network-request-failed',
        onRetry: (exception, attempt, maxAttempts) {
          log.w('$_tag: Retrying registration (attempt $attempt/$maxAttempts) after network error');
        },
      );

      if (userCredential.user != null) {
        if (displayName != null) {
          // Use retry for updating display name
          await RetryHelper.retry(
            operation: () async {
              await userCredential.user!.updateDisplayName(displayName);
              // Reload to get updated user info
              await userCredential.user!.reload();
            },
            maxRetries: 2,
            retryDelay: 1000,
            onRetry: (exception, attempt, maxAttempts) {
              log.w('$_tag: Retrying profile update (attempt $attempt/$maxAttempts) after error');
            },
          );
        }

        // Get fresh user data after update
        final updatedUser = firebaseAuth.currentUser;
        if (updatedUser != null) {
          return UserModel.fromFirebaseUser(updatedUser);
        } else {
          throw ServerException(message: 'User registration failed');
        }
      } else {
        throw ServerException(message: 'Registration failed');
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(message: e.message ?? 'Registration failed');
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Use retry mechanism for logout
      await RetryHelper.retry(
        operation: () => firebaseAuth.signOut(),
        maxRetries: 2,
        retryDelay: 1000,
        onRetry: (exception, attempt, maxAttempts) {
          log.w('$_tag: Retrying logout (attempt $attempt/$maxAttempts) after error');
        },
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(message: e.message ?? 'Logout failed');
    }
  }
}
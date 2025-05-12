import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> getCurrentUser();
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String password, String? displayName);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;

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
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
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
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        if (displayName != null) {
          await userCredential.user!.updateDisplayName(displayName);
          // Reload to get updated user info
          await userCredential.user!.reload();
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
      await firebaseAuth.signOut();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(message: e.message ?? 'Logout failed');
    }
  }
}
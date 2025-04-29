import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:musiva/features/settings/domain/entities/user_preferences.dart';

abstract class UserPreferencesDataSource {
  Future<UserPreferences> getUserPreferences();
  Future<void> saveUserPreferences(UserPreferences preferences);
}

class FirebaseUserPreferencesDataSource implements UserPreferencesDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseDatabase _firebaseDatabase;

  FirebaseUserPreferencesDataSource({
    required FirebaseAuth firebaseAuth,
    required FirebaseDatabase firebaseDatabase,
  })  : _firebaseAuth = firebaseAuth,
        _firebaseDatabase = firebaseDatabase;

  @override
  Future<UserPreferences> getUserPreferences() async {
    final user = _firebaseAuth.currentUser;

    // Return default preferences for anonymous users or when no user is logged in
    if (user == null || user.isAnonymous) {
      return const UserPreferences();
    }

    try {
      final snapshot = await _firebaseDatabase
          .ref()
          .child('user_preferences')
          .child(user.uid)
          .get();

      if (snapshot.exists) {
        return UserPreferences.fromJson(
            Map<String, dynamic>.from(snapshot.value as Map));
      } else {
        return const UserPreferences();
      }
    } catch (e) {
      // In case of error, return default preferences
      return const UserPreferences();
    }
  }

  @override
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    final user = _firebaseAuth.currentUser;

    // Don't save preferences for anonymous users
    if (user == null || user.isAnonymous) {
      return;
    }

    try {
      await _firebaseDatabase
          .ref()
          .child('user_preferences')
          .child(user.uid)
          .set(preferences.toJson());
    } catch (e) {
      // Handle error silently or rethrow based on your error handling strategy
      rethrow;
    }
  }
}
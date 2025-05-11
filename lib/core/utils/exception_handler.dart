import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'logger.dart';

/// A utility class for handling exceptions in a consistent way across the app.
class ExceptionHandler {
  /// Handles exceptions and returns a user-friendly error message.
  /// 
  /// This method logs the error and returns an appropriate message based on the exception type.
  static String handleException(dynamic exception, [StackTrace? stackTrace]) {
    log.e('Exception occurred', exception, stackTrace);
    
    if (exception is FirebaseAuthException) {
      return _handleFirebaseAuthException(exception);
    } else if (exception is FirebaseException) {
      return _handleFirebaseException(exception);
    } else if (exception is SocketException) {
      return 'Network error. Please check your internet connection.';
    } else if (exception is TimeoutException) {
      return 'Request timed out. Please try again.';
    } else if (exception is PlatformException) {
      return 'Platform error: ${exception.message}';
    } else if (exception is FormatException) {
      return 'Invalid data format received.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Handles Firebase Authentication exceptions.
  static String _handleFirebaseAuthException(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many unsuccessful login attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'invalid-credential':
        return 'The credential is invalid.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication error: ${exception.message}';
    }
  }

  /// Handles general Firebase exceptions.
  static String _handleFirebaseException(FirebaseException exception) {
    if (exception.plugin == 'firebase-storage') {
      return _handleFirebaseStorageException(exception);
    } else if (exception.plugin == 'firebase-database') {
      return _handleFirebaseDatabaseException(exception);
    } else {
      return 'Firebase error: ${exception.message}';
    }
  }

  /// Handles Firebase Storage exceptions.
  static String _handleFirebaseStorageException(FirebaseException exception) {
    switch (exception.code) {
      case 'storage/object-not-found':
        return 'The file does not exist.';
      case 'storage/unauthorized':
        return 'You are not authorized to access this file.';
      case 'storage/canceled':
        return 'The operation was canceled.';
      case 'storage/unknown':
        return 'An unknown error occurred with the file storage.';
      default:
        return 'Storage error: ${exception.message}';
    }
  }

  /// Handles Firebase Database exceptions.
  static String _handleFirebaseDatabaseException(FirebaseException exception) {
    switch (exception.code) {
      case 'permission-denied':
        return 'Permission denied to access the database.';
      case 'unavailable':
        return 'The database service is currently unavailable.';
      case 'database/permission-denied':
        return 'Permission denied to access the database.';
      case 'database/unavailable':
        return 'The database service is currently unavailable.';
      default:
        return 'Database error: ${exception.message}';
    }
  }

  /// Safely executes a function and handles any exceptions.
  /// 
  /// This method is useful for wrapping async operations that might throw exceptions.
  /// It returns a Result object containing either the result or an error message.
  static Future<Result<T>> safeCall<T>(Future<T> Function() function) async {
    try {
      final result = await function();
      return Result.success(result);
    } catch (e, stackTrace) {
      final errorMessage = handleException(e, stackTrace);
      return Result.error(errorMessage);
    }
  }
}

/// A class representing the result of an operation that might fail.
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  Result._({this.data, this.error, required this.isSuccess});

  factory Result.success(T data) {
    return Result._(data: data, isSuccess: true);
  }

  factory Result.error(String error) {
    return Result._(error: error, isSuccess: false);
  }
}
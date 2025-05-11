import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'logger.dart';

/// A utility class for retrying operations that might fail due to network issues.
class RetryHelper {
  /// Default number of retry attempts
  static const int defaultMaxRetries = 3;
  
  /// Default delay between retries in milliseconds
  static const int defaultRetryDelay = 1000;
  
  /// Default exponential backoff factor
  static const double defaultBackoffFactor = 1.5;

  /// Executes an operation with retry logic for network-related errors.
  /// 
  /// Parameters:
  /// - [operation]: The async function to execute and potentially retry
  /// - [maxRetries]: Maximum number of retry attempts (default: 3)
  /// - [retryDelay]: Initial delay between retries in milliseconds (default: 1000ms)
  /// - [backoffFactor]: Factor by which to increase delay on each retry (default: 1.5)
  /// - [retryIf]: Optional function to determine if a specific error should trigger a retry
  /// - [onRetry]: Optional callback that is called before each retry attempt
  /// 
  /// Returns the result of the operation if successful, otherwise throws the last error.
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxRetries = defaultMaxRetries,
    int retryDelay = defaultRetryDelay,
    double backoffFactor = defaultBackoffFactor,
    bool Function(Exception)? retryIf,
    void Function(Exception, int, int)? onRetry,
  }) async {
    int attempts = 0;
    
    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        // If we've used all retry attempts, rethrow the exception
        if (attempts > maxRetries) {
          log.e('Operation failed after $maxRetries retry attempts', e);
          rethrow;
        }
        
        // Check if this exception should trigger a retry
        final shouldRetry = _shouldRetry(e, retryIf);
        if (!shouldRetry) {
          log.w('Exception is not retryable, rethrowing', e);
          rethrow;
        }
        
        // Calculate delay with exponential backoff
        final currentDelay = (retryDelay * (backoffFactor * (attempts - 1))).toInt();
        
        // Log the retry attempt
        log.i('Retry attempt $attempts/$maxRetries after $currentDelay ms delay', e);
        
        // Notify about retry if callback is provided
        if (onRetry != null) {
          onRetry(e as Exception, attempts, maxRetries);
        }
        
        // Wait before retrying
        await Future.delayed(Duration(milliseconds: currentDelay));
      }
    }
  }
  
  /// Determines if an exception should trigger a retry.
  /// 
  /// By default, retries network-related exceptions like SocketException,
  /// TimeoutException, and certain Firebase exceptions related to network connectivity.
  static bool _shouldRetry(dynamic exception, bool Function(Exception)? retryIf) {
    // If a custom retry condition is provided, use it
    if (retryIf != null && exception is Exception) {
      return retryIf(exception);
    }
    
    // Default retry conditions for common network errors
    if (exception is SocketException) {
      return true;
    } else if (exception is TimeoutException) {
      return true;
    } else if (exception is FirebaseException) {
      // Retry for network-related Firebase errors
      final code = exception.code.toLowerCase();
      return code.contains('network') || 
             code.contains('unavailable') || 
             code.contains('timeout') ||
             code == 'deadline-exceeded';
    } else if (exception is FirebaseAuthException) {
      // Retry for network-related Firebase Auth errors
      return exception.code == 'network-request-failed';
    }
    
    return false;
  }
  
  /// Executes an operation with retry logic and returns a Result object.
  /// 
  /// This combines the retry logic with the Result pattern from ExceptionHandler.
  /// It's useful when you want to handle the result rather than catch exceptions.
  static Future<Result<T>> retryWithResult<T>({
    required Future<T> Function() operation,
    int maxRetries = defaultMaxRetries,
    int retryDelay = defaultRetryDelay,
    double backoffFactor = defaultBackoffFactor,
    bool Function(Exception)? retryIf,
    void Function(Exception, int, int)? onRetry,
  }) async {
    try {
      final result = await retry(
        operation: operation,
        maxRetries: maxRetries,
        retryDelay: retryDelay,
        backoffFactor: backoffFactor,
        retryIf: retryIf,
        onRetry: onRetry,
      );
      return Result.success(result);
    } catch (e) {
      return Result.error(e.toString());
    }
  }
}

/// A class representing the result of an operation that might fail.
/// This is the same as the Result class in exception_handler.dart but included here for convenience.
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
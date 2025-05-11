import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

/// A global error handler for the application.
/// 
/// This class provides methods for handling uncaught errors and exceptions
/// at the application level.
class GlobalErrorHandler {
  static const String _tag = 'GlobalErrorHandler';
  
  /// Initialize the global error handler.
  /// 
  /// This method should be called in the main function before runApp.
  static void init() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };
    
    // Handle errors from the Dart runtime
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true;
    };
    
    // Handle errors from isolates
    Isolate.current.addErrorListener(RawReceivePort((pair) {
      final List<dynamic> errorAndStacktrace = pair;
      _handleIsolateError(errorAndStacktrace[0], errorAndStacktrace[1]);
    }).sendPort);
    
    // Set up zone-level error handling
    runZonedGuarded(() {
      // This is where the app would be started
      // The actual app startup is in main.dart
    }, (error, stackTrace) {
      _handleZoneError(error, stackTrace);
    });
  }
  
  /// Handle Flutter framework errors.
  static void _handleFlutterError(FlutterErrorDetails details) {
    log.e(
      '$_tag: Flutter framework error',
      details.exception,
      details.stack,
    );
    
    // Report to crash reporting service if in production
    if (kReleaseMode) {
      // TODO: Report to crash reporting service
    }
  }
  
  /// Handle errors from the Dart runtime.
  static void _handlePlatformError(Object error, StackTrace stack) {
    log.e(
      '$_tag: Platform error',
      error,
      stack,
    );
    
    // Report to crash reporting service if in production
    if (kReleaseMode) {
      // TODO: Report to crash reporting service
    }
  }
  
  /// Handle errors from isolates.
  static void _handleIsolateError(Object error, StackTrace stack) {
    log.e(
      '$_tag: Isolate error',
      error,
      stack,
    );
    
    // Report to crash reporting service if in production
    if (kReleaseMode) {
      // TODO: Report to crash reporting service
    }
  }
  
  /// Handle errors from the Zone.
  static void _handleZoneError(Object error, StackTrace stack) {
    log.e(
      '$_tag: Uncaught error in zone',
      error,
      stack,
    );
    
    // Report to crash reporting service if in production
    if (kReleaseMode) {
      // TODO: Report to crash reporting service
    }
  }
  
  /// Show an error dialog to the user.
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  /// Show a snackbar with an error message.
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
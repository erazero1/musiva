import 'package:logger/logger.dart';

/// A centralized logging service for the application.
/// 
/// This class provides methods for logging at different levels
/// and ensures consistent logging throughout the app.
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  late Logger _logger;

  /// Singleton instance of AppLogger
  factory AppLogger() => _instance;

  AppLogger._internal() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2, // Number of method calls to be displayed
        errorMethodCount: 8, // Number of method calls if stacktrace is provided
        lineLength: 120, // Width of the output
        colors: true, // Colorful log messages
        printEmojis: true, // Print an emoji for each log message
        printTime: true, // Should each log print contain a timestamp
      ),
      level: Level.verbose, // Log level
    );
  }

  /// Logs a verbose message
  void v(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.v('$message\nError: $error', error: error, stackTrace: stackTrace);
    } else {
      _logger.v(message);
    }
  }

  /// Logs a debug message
  void d(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.d('$message\nError: $error', error: error, stackTrace: stackTrace);
    } else {
      _logger.d(message);
    }
  }

  /// Logs an info message
  void i(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.i('$message\nError: $error', error: error, stackTrace: stackTrace);
    } else {
      _logger.i(message);
    }
  }

  /// Logs a warning message
  void w(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.w('$message\nError: $error', error: error, stackTrace: stackTrace);
    } else {
      _logger.w(message);
    }
  }

  /// Logs an error message
  void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.e('$message\nError: $error', error: error, stackTrace: stackTrace);
    } else {
      _logger.e(message);
    }
  }

  /// Logs a fatal error message
  void wtf(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.wtf('$message\nError: $error', error: error, stackTrace: stackTrace);
    } else {
      _logger.wtf(message);
    }
  }
}

/// Global logger instance for easy access throughout the app
final log = AppLogger();
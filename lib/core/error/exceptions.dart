class Exception {
  final String? message;

  Exception({this.message});
}

class ServerException extends Exception {
  ServerException({String? message}) : super(message: message);
}

class CacheException extends Exception {
  CacheException({String? message}) : super(message: message);
}

class NetworkException extends Exception {
  NetworkException({String? message = 'No internet connection'}) : super(message: message);
}

class AuthException extends Exception {
  AuthException({String? message}) : super(message: message);
}

class ValidationException extends Exception {
  ValidationException({String? message}) : super(message: message);
}
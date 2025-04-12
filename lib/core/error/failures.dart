import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String? message;

  const Failure({this.message});

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure({String? message}) : super(message: message);
}

class CacheFailure extends Failure {
  const CacheFailure({String? message}) : super(message: message);
}

class NetworkFailure extends Failure {
  const NetworkFailure({String? message = 'No internet connection'}) : super(message: message);
}

class AuthFailure extends Failure {
  const AuthFailure({String? message}) : super(message: message);
}

class ValidationFailure extends Failure {
  const ValidationFailure({String? message}) : super(message: message);
}
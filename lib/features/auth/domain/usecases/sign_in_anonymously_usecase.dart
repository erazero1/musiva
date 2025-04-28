import '../repositories/auth_repository.dart';

class SignInAnonymouslyUseCase {
  final AuthRepository repository;

  SignInAnonymouslyUseCase(this.repository);

  Future<bool> call() async {
    return await repository.signInAnonymously();
  }
}

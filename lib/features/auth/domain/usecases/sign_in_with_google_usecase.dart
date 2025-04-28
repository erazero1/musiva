import '../repositories/auth_repository.dart';

class SignInWithGoogleUseCase {
  final AuthRepository repository;

  SignInWithGoogleUseCase(this.repository);

  Future<bool> call() async {
    return await repository.signInWithGoogle();
  }
}

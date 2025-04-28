import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../domain/entities/user.dart' as domain;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/register.dart';
import '../../domain/usecases/sign_in_anonymously_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';

part 'auth_event.dart';

part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentUser getCurrentUser;
  final Login login;
  final Register register;
  final Logout logout;
  final SignInAnonymouslyUseCase signInAnonymouslyUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final AuthRepository authRepository;

  AuthBloc({
    required this.getCurrentUser,
    required this.login,
    required this.register,
    required this.logout,
    required this.signInAnonymouslyUseCase,
    required this.signInWithGoogleUseCase,
    required this.authRepository,
  }) : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<SignInAnonymouslyEvent>(_onSignInAnonymously);
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
    on<CheckGuestModeEvent>(_onCheckGuestMode);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    Future.delayed(Duration(seconds: 2));
    final currentUser = await getCurrentUser(NoParams());

    currentUser.fold(
      (failure) => emit(Unauthenticated()),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onLogin(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await login(LoginParams(
      email: event.email,
      password: event.password,
    ));

    result.fold(
      (failure) => emit(AuthError(failure.message ?? 'Login failed')),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onRegister(
    RegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await register(RegisterParams(
      email: event.email,
      password: event.password,
      displayName: event.displayName,
    ));

    result.fold(
      (failure) => emit(AuthError(failure.message ?? 'Registration failed')),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await logout(NoParams());

    result.fold(
      (failure) => emit(AuthError(failure.message ?? 'Logout failed')),
      (_) => emit(Unauthenticated()),
    );
  }

  Future<void> _onSignInAnonymously(
    SignInAnonymouslyEvent event,
    Emitter<AuthState> emit,
  ) async {
    final success = await signInAnonymouslyUseCase();
    if (success) {
      emit(GuestAuthenticated());
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    final success = await signInWithGoogleUseCase();
    if (success) {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        emit(Authenticated(mapFirebaseUserToDomainUser(user)));
      } else {
        emit(const AuthError('Google sign-in failed: no user'));
      }
    } else {
      emit(const AuthError('Google sign-in failed'));
    }
  }

  void _onCheckGuestMode(
    CheckGuestModeEvent event,
    Emitter<AuthState> emit,
  ) {
    if (authRepository.isGuest()) {
      emit(GuestAuthenticated());
    } else {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        emit(Authenticated(mapFirebaseUserToDomainUser(user)));
      } else {
        emit(Unauthenticated());
      }
    }
  }

  domain.User mapFirebaseUserToDomainUser(firebase_auth.User firebaseUser) {
    return domain.User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '',
    );
  }
}

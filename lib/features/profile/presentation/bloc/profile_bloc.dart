import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:musiva/core/usecases/usecase.dart';
import 'package:musiva/features/auth/domain/usecases/get_current_user.dart';
import 'package:musiva/features/auth/domain/usecases/logout.dart';

import '../../../auth/domain/entities/user.dart';

part 'profile_event.dart';

part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetCurrentUser getCurrentUserUseCase;
  final Logout logoutUseCase;

  ProfileBloc({
    required this.getCurrentUserUseCase,
    required this.logoutUseCase,
  }) : super(ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
  }

  Future<void> _onLoadProfile(
    LoadProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await getCurrentUserUseCase.call(NoParams());
    result.fold((failure) => emit(ProfileError("Did not got current user")),
        (user) => emit(ProfileLoaded(user)));
  }

  Future<void> logout() async {
    try {
      await logoutUseCase.call(NoParams());
    } catch (e) {
      debugPrint("Something went wrong: $e");
    }
  }
}

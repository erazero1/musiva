import 'package:get_it/get_it.dart';

import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/domain/usecases/logout.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';

void initProfileFeature() {
  GetIt.instance.registerFactory(
        () => ProfileBloc(
      // Reuse existing use cases from auth feature
      getCurrentUserUseCase: GetIt.instance<GetCurrentUser>(),
      logoutUseCase: GetIt.instance<Logout>(),
    ),
  );

}
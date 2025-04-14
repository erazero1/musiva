import 'package:get_it/get_it.dart';
import 'package:musiva/core/constants/env.dart';
import 'package:musiva/features/songs/domain/repositories/songs_repository.dart';
import 'package:musiva/features/songs/presentation/bloc/songs_bloc.dart';

import 'data/repositories/songs_repository_impl.dart';

final sl = GetIt.instance;

Future<void> initSongsDependencies() async {
  // BLoC
  sl.registerFactory(
    () => SongsBloc(
      songsRepository: sl(),
    ),
  );
  // Repository
  sl.registerLazySingleton<SongsRepository>(
    () => SongsRepositoryImpl(
        clientId: Env.clientIdKey,
        clientSecret: Env.clientSecretKey),
  );


}

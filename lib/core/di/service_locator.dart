import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/domain/usecases/login.dart';
import '../../features/auth/domain/usecases/logout.dart';
import '../../features/auth/domain/usecases/register.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/song_upload/data/datasources/cloudinary_datasource.dart';
import '../../features/song_upload/data/repositories/song_repository_impl.dart';
import '../../features/song_upload/domain/repositories/song_repository.dart';
import '../../features/song_upload/domain/usecases/upload_song_usecase.dart';
import '../../features/song_upload/presentation/bloc/song_upload_bloc.dart';
import '../../features/songs/data/repositories/songs_repository_impl.dart';
import '../../features/songs/domain/repositories/songs_repository.dart';
import '../../features/songs/presentation/bloc/songs_bloc.dart';
import '../constants/env.dart';
import '../network/network_info.dart';

final sl = GetIt.instance;

void setupDependencies() async {
  initAuthDependencies();
  sl.registerFactory(
    () => SongsBloc(
      songsRepository: sl<SongsRepository>(),
    ),
  );
  // Repository
  sl.registerLazySingleton<SongsRepository>(
    () => SongsRepositoryImpl(
      clientId: Env.clientIdKey,
      clientSecret: Env.clientSecretKey,
    ),
  );

  sl.registerFactory(
    () => ProfileBloc(
      // Reuse existing use cases from auth feature
      getCurrentUserUseCase: sl<GetCurrentUser>(),
      logoutUseCase: sl<Logout>(),
    ),
  );

  sl.registerLazySingleton(() => CloudinaryPublic(
        'dsspxotii',
        'preset_for_mobile',
        cache: false,
      ));

  // Data sources
  sl.registerLazySingleton(() => CloudinaryDataSource(sl()));

  // Repositories
  sl.registerLazySingleton<SongRepository>(() => SongRepositoryImpl(sl()));

  // Use cases
  sl.registerLazySingleton(() => UploadSongUseCase(sl()));

  // BLoCs
  sl.registerFactory(() => SongUploadBloc(sl()));
}

Future<void> initAuthDependencies() async {
  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      getCurrentUser: sl(),
      login: sl(),
      register: sl(),
      logout: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => Login(sl()));
  sl.registerLazySingleton(() => Register(sl()));
  sl.registerLazySingleton(() => Logout(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: sl()),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // Core
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );

  // External
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => InternetConnectionChecker.instance);

  // Register SharedPreferences singleton if not already registered
  if (!sl.isRegistered<SharedPreferences>()) {
    final sharedPreferences = await SharedPreferences.getInstance();
    sl.registerLazySingleton(() => sharedPreferences);
  }
}

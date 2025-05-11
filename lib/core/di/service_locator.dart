import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:musiva/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:musiva/features/song_upload/data/datasources/firebase_storage_datasource.dart';
import 'package:musiva/features/songs/data/datasources/firebase_database_datasource.dart';
import 'package:musiva/features/songs/data/repositories/firebase_songs_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/domain/usecases/login.dart';
import '../../features/auth/domain/usecases/logout.dart';
import '../../features/auth/domain/usecases/register.dart';
import '../../features/auth/domain/usecases/sign_in_anonymously_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/settings/data/datasources/user_preferences_data_source.dart';
import '../../features/settings/data/repositories/user_preferences_repository_impl.dart';
import '../../features/settings/domain/repositories/user_preferences_repository.dart';
import '../../features/settings/domain/usecases/get_user_preferences.dart';
import '../../features/settings/domain/usecases/save_user_preferences.dart';
import '../../features/settings/presentation/bloc/user_preferences_bloc.dart';
import '../../features/song_upload/data/datasources/cloudinary_datasource.dart';
import '../../features/song_upload/data/repositories/song_repository_impl.dart';
import '../../features/song_upload/domain/repositories/song_repository.dart';
import '../../features/song_upload/domain/usecases/upload_song_usecase.dart';
import '../../features/song_upload/presentation/bloc/song_upload_bloc.dart';
import '../../features/songs/domain/repositories/songs_repository.dart';
import '../../features/songs/presentation/bloc/songs_bloc.dart';
import '../constants/env.dart';
import '../network/network_info.dart';
import '../theme/bloc/theme_bloc.dart';

final sl = GetIt.instance;

Future<void> setupDependencies() async {
  await initAuthDependencies();
  sl.registerFactory(() => ThemeBloc(userPreferencesBloc: sl()));
  sl.registerFactory(
    () => SongsBloc(
      songsRepository: sl<SongsRepository>(),
    ),
  );
  
  // Firebase Database Data Source
  sl.registerLazySingleton(
    () => FirebaseDatabaseDataSource(),
  );
  
  // Repository
  sl.registerLazySingleton<SongsRepository>(
    () => FirebaseSongsRepositoryImpl(sl()),
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
  sl.registerLazySingleton(() => FirebaseStorageDataSource());

  // Repositories
  sl.registerLazySingleton<SongRepository>(() => SongRepositoryImpl(sl()));

  // Use cases
  sl.registerLazySingleton(() => UploadSongUseCase(sl()));

  // BLoCs
  sl.registerFactory(() => SongUploadBloc(sl()));
}

Future<void> initSettingsFeature() async {
  // BLoC
  sl.registerFactory(
        () => UserPreferencesBloc(
      getUserPreferences: sl(),
      saveUserPreferences: sl(),
    ),
  );


  // Use cases
  sl.registerLazySingleton(() => GetUserPreferences(sl()));
  sl.registerLazySingleton(() => SaveUserPreferences(sl()));

  // Repository
  sl.registerLazySingleton<UserPreferencesRepository>(
        () => UserPreferencesRepositoryImpl(dataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<UserPreferencesDataSource>(
        () => FirebaseUserPreferencesDataSource(
      firebaseAuth: sl(),
      firebaseDatabase: sl(),
    ),
  );

  // External
  sl.registerLazySingleton(() => FirebaseDatabase.instance);
}

Future<void> initAuthDependencies() async {
  // External
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => InternetConnectionChecker.instance);

  // Register SharedPreferences singleton early
  if (!sl.isRegistered<SharedPreferences>()) {
    final sharedPreferences = await SharedPreferences.getInstance();
    sl.registerLazySingleton(() => sharedPreferences);
  }

  // Core
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: sl()),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      firebaseAuth: sl(),
      googleSignIn: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => Login(sl()));
  sl.registerLazySingleton(() => Register(sl()));
  sl.registerLazySingleton(() => Logout(sl()));
  sl.registerLazySingleton(() => GoogleSignIn());
  sl.registerLazySingleton(() => SignInAnonymouslyUseCase(sl()));
  sl.registerLazySingleton(() => SignInWithGoogleUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      getCurrentUser: sl(),
      login: sl(),
      register: sl(),
      logout: sl(),
      signInAnonymouslyUseCase: sl(),
      signInWithGoogleUseCase: sl(),
      authRepository: sl(),
    ),
  );
}

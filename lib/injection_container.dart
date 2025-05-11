import 'package:get_it/get_it.dart';
import 'package:musiva/features/songs/data/datasources/firebase_database_datasource.dart';
import 'package:musiva/features/songs/data/repositories/firebase_songs_repository_impl.dart';
import 'package:musiva/features/songs/domain/repositories/songs_repository.dart';
import 'package:musiva/features/songs/presentation/bloc/songs_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Features - Songs
  // Bloc
  sl.registerFactory(
    () => SongsBloc(songsRepository: sl()),
  );

  // Repositories
  sl.registerLazySingleton<SongsRepository>(
    () => FirebaseSongsRepositoryImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton(
    () => FirebaseDatabaseDataSource(),
  );
}
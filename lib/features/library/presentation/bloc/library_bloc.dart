import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../songs/domain/entities/song.dart';
import '../../data/repositories/library_repository_impl.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/repositories/library_repository.dart';

part 'library_event.dart';

part 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  // TODO: change from creating instance here to injecting it
  final LibraryRepository _libraryRepository = LibraryRepositoryImpl();

  LibraryBloc() : super(const LibraryState()) {
    on<FetchLibrary>(_onFetchLibrary);
  }

  Future<void> _onFetchLibrary(
      FetchLibrary event, Emitter<LibraryState> emit) async {
    emit(state.copyWith(status: LibraryStatus.loading));

    try {
      final recentSongs = await _libraryRepository.getRecentSongs();
      final playlists = await _libraryRepository.getPlaylists();
      final favorites = await _libraryRepository.getFavoriteSongs();
      final downloads = await _libraryRepository.getDownloadedSongs();

      emit(state.copyWith(
        status: LibraryStatus.success,
        recentSongs: recentSongs,
        playlists: playlists,
        favorites: favorites,
        downloads: downloads,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: LibraryStatus.failure,
        error: e.toString(),
      ));
    }
  }
}

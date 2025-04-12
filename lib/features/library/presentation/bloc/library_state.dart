part of 'library_bloc.dart';

enum LibraryStatus { initial, loading, success, failure }

class LibraryState extends Equatable {
  final LibraryStatus status;
  final List<Song> recentSongs;
  final List<Playlist> playlists;
  final List<Song> favorites;
  final List<Song> downloads;
  final String error;

  const LibraryState({
    this.status = LibraryStatus.initial,
    this.recentSongs = const [],
    this.playlists = const [],
    this.favorites = const [],
    this.downloads = const [],
    this.error = '',
  });

  LibraryState copyWith({
    LibraryStatus? status,
    List<Song>? recentSongs,
    List<Playlist>? playlists,
    List<Song>? favorites,
    List<Song>? downloads,
    String? error,
  }) {
    return LibraryState(
      status: status ?? this.status,
      recentSongs: recentSongs ?? this.recentSongs,
      playlists: playlists ?? this.playlists,
      favorites: favorites ?? this.favorites,
      downloads: downloads ?? this.downloads,
      error: error ?? this.error,
    );
  }

  @override
  List<Object> get props =>
      [status, recentSongs, playlists, favorites, downloads, error];
}

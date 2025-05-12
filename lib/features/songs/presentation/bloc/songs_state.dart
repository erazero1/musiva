part of 'songs_bloc.dart';

enum SongsStatus { initial, loading, success, failure }

class SongsState extends Equatable {
  final SongsStatus status;
  final List<Song> songs;
  final List<Song> featuredSongs;
  final List<Song> filteredSongs;
  final String selectedCategory;
  final String error;

  const SongsState({
    this.status = SongsStatus.initial,
    this.songs = const [],
    this.featuredSongs = const [],
    this.filteredSongs = const [],
    this.selectedCategory = 'All',
    this.error = '',
  });

  SongsState copyWith({
    SongsStatus? status,
    List<Song>? songs,
    List<Song>? featuredSongs,
    List<Song>? filteredSongs,
    String? selectedCategory,
    String? error,
  }) {
    return SongsState(
      status: status ?? this.status,
      songs: songs ?? this.songs,
      featuredSongs: featuredSongs ?? this.featuredSongs,
      filteredSongs: filteredSongs ?? this.filteredSongs,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      error: error ?? this.error,
    );
  }

  @override
  List<Object> get props => [status, songs, featuredSongs, filteredSongs, selectedCategory, error];
}
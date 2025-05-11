part of 'songs_bloc.dart';

abstract class SongsEvent extends Equatable {
  const SongsEvent();

  @override
  List<Object?> get props => [];
}

class FetchSongs extends SongsEvent {
  final bool refresh;
  
  const FetchSongs({this.refresh = false});
  
  @override
  List<Object> get props => [refresh];
}

class LoadMoreSongs extends SongsEvent {
  const LoadMoreSongs();
}

class CategorySelected extends SongsEvent {
  final String category;

  const CategorySelected(this.category);

  @override
  List<Object> get props => [category];
}

class SearchSongs extends SongsEvent {
  final String query;
  
  const SearchSongs(this.query);
  
  @override
  List<Object> get props => [query];
}

class ClearSearch extends SongsEvent {
  const ClearSearch();
}

class SongPlayed extends SongsEvent {
  final String songId;
  
  const SongPlayed(this.songId);
  
  @override
  List<Object> get props => [songId];
}
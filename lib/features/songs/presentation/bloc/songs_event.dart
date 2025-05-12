part of 'songs_bloc.dart';

abstract class SongsEvent extends Equatable {
  const SongsEvent();

  @override
  List<Object> get props => [];
}

class FetchSongs extends SongsEvent {
  const FetchSongs();
}

class CategorySelected extends SongsEvent {
  final String category;

  const CategorySelected(this.category);

  @override
  List<Object> get props => [category];
}
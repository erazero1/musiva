import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/songs_repository_impl.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/songs_repository.dart';

part 'songs_event.dart';

part 'songs_state.dart';

class SongsBloc extends Bloc<SongsEvent, SongsState> {
  // TODO: Change from creating instance here to inject it
  final SongsRepository songsRepository;



  SongsBloc({required this.songsRepository}) : super(const SongsState()) {
    on<FetchSongs>(_onFetchSongs);
    on<CategorySelected>(_onCategorySelected);
  }

  Future<void> _onFetchSongs(FetchSongs event, Emitter<SongsState> emit) async {
    emit(state.copyWith(status: SongsStatus.loading));

    try {
      final songs = await songsRepository.getSongs();
      final featuredSongs = await songsRepository.getFeaturedSongs();

      emit(state.copyWith(
        status: SongsStatus.success,
        songs: songs,
        featuredSongs: featuredSongs,
        filteredSongs: songs,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SongsStatus.failure,
        error: e.toString(),
      ));
    }
  }

  void _onCategorySelected(CategorySelected event, Emitter<SongsState> emit) {
    final category = event.category;
    List<Song> filteredSongs;

    // TODO: Filter songs based on category
    if (category == 'All') {
      filteredSongs = List.from(state.songs);
    } else if (category == 'Recent') {
      // TODO: Sort by most recent
      filteredSongs = List.from(state.songs)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (category == 'Popular') {
      // TODO: Sort by plays
      filteredSongs = List.from(state.songs)
        ..sort((a, b) => b.plays.compareTo(a.plays));
    } else {
      // TODO: For other categories implement appropriate filtering
      filteredSongs = List.from(state.songs);
    }

    emit(state.copyWith(
      selectedCategory: category,
      filteredSongs: filteredSongs,
    ));
  }
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:musiva/core/utils/exception_handler.dart';
import 'package:musiva/core/utils/logger.dart';

import '../../domain/entities/song.dart';
import '../../domain/repositories/songs_repository.dart';

part 'songs_event.dart';
part 'songs_state.dart';

class SongsBloc extends Bloc<SongsEvent, SongsState> {
  final SongsRepository songsRepository;
  static const int _pageSize = 10;
  static const String _tag = 'SongsBloc';

  SongsBloc({required this.songsRepository}) : super(const SongsState()) {
    on<FetchSongs>(_onFetchSongs);
    on<LoadMoreSongs>(_onLoadMoreSongs);
    on<CategorySelected>(_onCategorySelected);
    on<SearchSongs>(_onSearchSongs);
    on<ClearSearch>(_onClearSearch);
    on<SongPlayed>(_onSongPlayed);
  }

  Future<void> _onFetchSongs(FetchSongs event, Emitter<SongsState> emit) async {
    log.i('$_tag: Fetching songs - refresh: ${event.refresh}');
    
    if (event.refresh) {
      emit(state.copyWith(
        status: SongsStatus.loading,
        currentPage: 1,
        hasReachedMax: false,
      ));
      log.d('$_tag: State reset for refresh');
    } else if (state.status == SongsStatus.success) {
      log.d('$_tag: Already in success state, skipping fetch');
      return;
    } else {
      emit(state.copyWith(status: SongsStatus.loading));
      log.d('$_tag: Set loading state');
    }

    try {
      log.d('$_tag: Getting total songs count');
      // Get total songs count for pagination
      final totalSongs = await songsRepository.getTotalSongs();
      log.d('$_tag: Total songs: $totalSongs');
      
      // Get songs with sorting based on selected category
      String? sortBy;
      bool descending = true;
      
      if (state.selectedCategory == 'Recent') {
        sortBy = 'createdAt';
        descending = true;
      } else if (state.selectedCategory == 'Popular') {
        sortBy = 'plays';
        descending = true;
      } else if (state.selectedCategory == 'Trending') {
        sortBy = 'plays';
        descending = true;
      }
      
      log.d('$_tag: Fetching songs with sortBy: $sortBy, descending: $descending');
      final songs = await songsRepository.getSongs(
        page: 1,
        sortBy: sortBy,
        descending: descending,
      );
      log.d('$_tag: Fetched ${songs.length} songs');
      
      // Get featured songs
      log.d('$_tag: Fetching featured songs');
      final featuredSongs = await songsRepository.getFeaturedSongs();
      log.d('$_tag: Fetched ${featuredSongs.length} featured songs');

      // Calculate if we've reached max
      final hasReachedMax = songs.length < _pageSize || songs.length >= totalSongs;
      log.d('$_tag: Has reached max: $hasReachedMax');

      emit(state.copyWith(
        status: SongsStatus.success,
        songs: songs,
        featuredSongs: featuredSongs,
        filteredSongs: songs,
        currentPage: 1,
        hasReachedMax: hasReachedMax,
        totalSongs: totalSongs,
        sortBy: sortBy ?? 'createdAt',
        sortDescending: descending,
      ));
      log.i('$_tag: Successfully fetched songs and updated state');
    } catch (e, stackTrace) {
      final errorMsg = ExceptionHandler.handleException(e, stackTrace);
      log.e('$_tag: Failed to fetch songs: $errorMsg', e, stackTrace);
      
      emit(state.copyWith(
        status: SongsStatus.failure,
        error: errorMsg,
      ));
    }
  }

  Future<void> _onLoadMoreSongs(LoadMoreSongs event, Emitter<SongsState> emit) async {
    log.i('$_tag: Loading more songs');
    
    if (state.hasReachedMax) {
      log.d('$_tag: Already reached max, skipping load more');
      return;
    }
    
    emit(state.copyWith(status: SongsStatus.loadingMore));
    log.d('$_tag: Set loadingMore state');
    
    try {
      final nextPage = state.currentPage + 1;
      log.d('$_tag: Loading page $nextPage');
      
      // Get more songs with the same sorting as current
      final moreSongs = await songsRepository.getSongs(
        page: nextPage,
        sortBy: state.sortBy,
        descending: state.sortDescending,
      );
      log.d('$_tag: Loaded ${moreSongs.length} more songs');
      
      // If no more songs, we've reached max
      if (moreSongs.isEmpty) {
        log.d('$_tag: No more songs available, reached max');
        emit(state.copyWith(
          status: SongsStatus.success,
          hasReachedMax: true,
        ));
        return;
      }
      
      // Combine existing and new songs
      final updatedSongs = List<Song>.from(state.songs)..addAll(moreSongs);
      log.d('$_tag: Combined songs count: ${updatedSongs.length}');
      
      // Update filtered songs based on category
      log.d('$_tag: Filtering songs by category: ${state.selectedCategory}');
      List<Song> updatedFilteredSongs = _filterSongsByCategory(
        updatedSongs, 
        state.selectedCategory,
      );
      
      // Calculate if we've reached max
      final hasReachedMax = moreSongs.length < _pageSize || 
                           updatedSongs.length >= state.totalSongs;
      log.d('$_tag: Has reached max: $hasReachedMax');
      
      emit(state.copyWith(
        status: SongsStatus.success,
        songs: updatedSongs,
        filteredSongs: updatedFilteredSongs,
        currentPage: nextPage,
        hasReachedMax: hasReachedMax,
      ));
      log.i('$_tag: Successfully loaded more songs and updated state');
    } catch (e, stackTrace) {
      final errorMsg = ExceptionHandler.handleException(e, stackTrace);
      log.e('$_tag: Failed to load more songs: $errorMsg', e, stackTrace);
      
      emit(state.copyWith(
        status: SongsStatus.failure,
        error: errorMsg,
      ));
    }
  }

  Future<void> _onCategorySelected(CategorySelected event, Emitter<SongsState> emit) async {
    final category = event.category;
    log.i('$_tag: Category selected: $category');
    
    // First update UI with filtered songs from current data
    log.d('$_tag: Filtering current songs by selected category');
    List<Song> filteredSongs = _filterSongsByCategory(state.songs, category);
    
    emit(state.copyWith(
      selectedCategory: category,
      filteredSongs: filteredSongs,
    ));
    log.d('$_tag: Updated state with filtered songs');
    
    // Then fetch fresh data with the appropriate sorting
    String? sortBy;
    bool descending = true;
    
    if (category == 'Recent') {
      sortBy = 'createdAt';
      descending = true;
    } else if (category == 'Popular') {
      sortBy = 'plays';
      descending = true;
    } else if (category == 'Trending') {
      sortBy = 'plays';
      descending = true;
    }
    
    log.d('$_tag: Determined sort parameters - sortBy: $sortBy, descending: $descending');
    
    try {
      emit(state.copyWith(status: SongsStatus.loading));
      log.d('$_tag: Set loading state for category fetch');
      
      final songs = await songsRepository.getSongs(
        page: 1,
        sortBy: sortBy,
        descending: descending,
      );
      log.d('$_tag: Fetched ${songs.length} songs for category: $category');
      
      filteredSongs = _filterSongsByCategory(songs, category);
      log.d('$_tag: Filtered songs count: ${filteredSongs.length}');
      
      emit(state.copyWith(
        status: SongsStatus.success,
        songs: songs,
        filteredSongs: filteredSongs,
        currentPage: 1,
        hasReachedMax: songs.length < _pageSize,
        sortBy: sortBy ?? 'createdAt',
        sortDescending: descending,
      ));
      log.i('$_tag: Successfully updated state with category filtered songs');
    } catch (e, stackTrace) {
      final errorMsg = ExceptionHandler.handleException(e, stackTrace);
      log.e('$_tag: Failed to fetch songs for category: $errorMsg', e, stackTrace);
      
      // If fetch fails, keep the current songs but show error
      emit(state.copyWith(
        status: SongsStatus.failure,
        error: errorMsg,
      ));
    }
  }

  Future<void> _onSearchSongs(SearchSongs event, Emitter<SongsState> emit) async {
    final query = event.query;
    log.i('$_tag: Searching songs with query: $query');
    
    if (query.isEmpty) {
      log.d('$_tag: Empty query, clearing search');
      return add(const ClearSearch());
    }
    
    emit(state.copyWith(
      status: SongsStatus.searchLoading,
      searchQuery: query,
    ));
    log.d('$_tag: Set searchLoading state');
    
    try {
      final searchResults = await songsRepository.searchSongs(query);
      log.d('$_tag: Search returned ${searchResults.length} results');
      
      emit(state.copyWith(
        status: SongsStatus.searchSuccess,
        searchResults: searchResults,
      ));
      log.i('$_tag: Successfully updated state with search results');
    } catch (e, stackTrace) {
      final errorMsg = ExceptionHandler.handleException(e, stackTrace);
      log.e('$_tag: Search failed: $errorMsg', e, stackTrace);
      
      emit(state.copyWith(
        status: SongsStatus.searchFailure,
        error: errorMsg,
      ));
    }
  }

  void _onClearSearch(ClearSearch event, Emitter<SongsState> emit) {
    log.i('$_tag: Clearing search');
    
    emit(state.copyWith(
      status: SongsStatus.success,
      searchQuery: '',
      searchResults: [],
    ));
    log.d('$_tag: Search cleared, returned to success state');
  }

  Future<void> _onSongPlayed(SongPlayed event, Emitter<SongsState> emit) async {
    final songId = event.songId;
    log.i('$_tag: Song played: $songId');
    
    try {
      await songsRepository.incrementPlayCount(songId);
      log.d('$_tag: Play count incremented in repository');
      
      // Update the song in our local state
      log.d('$_tag: Updating song in local state');
      final updatedSongs = state.songs.map((song) {
        if (song.id == songId) {
          log.d('$_tag: Incrementing play count for song: ${song.title}');
          return Song(
            id: song.id,
            title: song.title,
            artist: song.artist,
            artworkUrl: song.artworkUrl,
            duration: song.duration,
            audioUrl: song.audioUrl,
            createdAt: song.createdAt,
            plays: song.plays + 1,
          );
        }
        return song;
      }).toList();
      
      // Update filtered songs as well
      log.d('$_tag: Updating filtered songs');
      final updatedFilteredSongs = state.filteredSongs.map((song) {
        if (song.id == songId) {
          return Song(
            id: song.id,
            title: song.title,
            artist: song.artist,
            artworkUrl: song.artworkUrl,
            duration: song.duration,
            audioUrl: song.audioUrl,
            createdAt: song.createdAt,
            plays: song.plays + 1,
          );
        }
        return song;
      }).toList();
      
      emit(state.copyWith(
        songs: updatedSongs,
        filteredSongs: updatedFilteredSongs,
      ));
      log.i('$_tag: Successfully updated state with incremented play count');
    } catch (e, stackTrace) {
      // Silently fail - no need to show error to user for play count
      log.w('$_tag: Failed to increment play count: ${e.toString()}', e, stackTrace);
    }
  }
  
  // Helper method to filter songs by category
  List<Song> _filterSongsByCategory(List<Song> songs, String category) {
    log.d('$_tag: Filtering ${songs.length} songs by category: $category');
    
    if (category == 'All') {
      log.d('$_tag: Returning all songs without filtering');
      return List.from(songs);
    } else if (category == 'Recent') {
      log.d('$_tag: Sorting songs by creation date');
      return List.from(songs)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (category == 'Popular') {
      log.d('$_tag: Sorting songs by play count');
      return List.from(songs)
        ..sort((a, b) => b.plays.compareTo(a.plays));
    } else if (category == 'Trending') {
      // For trending, we could use a combination of recency and plays
      log.d('$_tag: Calculating trending scores and sorting');
      return List.from(songs)
        ..sort((a, b) {
          // Calculate a "trending score" based on plays and recency
          final aScore = a.plays * (1 + 1 / (DateTime.now().difference(a.createdAt).inDays + 1));
          final bScore = b.plays * (1 + 1 / (DateTime.now().difference(b.createdAt).inDays + 1));
          return bScore.compareTo(aScore);
        });
    } else {
      log.d('$_tag: Unknown category, returning all songs');
      return List.from(songs);
    }
  }
}

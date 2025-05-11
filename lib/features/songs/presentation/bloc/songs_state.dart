part of 'songs_bloc.dart';

enum SongsStatus { initial, loading, success, failure, loadingMore, searchLoading, searchSuccess, searchFailure }

class SongsState extends Equatable {
  final SongsStatus status;
  final List<Song> songs;
  final List<Song> featuredSongs;
  final List<Song> filteredSongs;
  final String selectedCategory;
  final String error;
  final int currentPage;
  final bool hasReachedMax;
  final int totalSongs;
  final String searchQuery;
  final List<Song> searchResults;
  final String sortBy;
  final bool sortDescending;

  const SongsState({
    this.status = SongsStatus.initial,
    this.songs = const [],
    this.featuredSongs = const [],
    this.filteredSongs = const [],
    this.selectedCategory = 'All',
    this.error = '',
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.totalSongs = 0,
    this.searchQuery = '',
    this.searchResults = const [],
    this.sortBy = 'createdAt',
    this.sortDescending = true,
  });

  SongsState copyWith({
    SongsStatus? status,
    List<Song>? songs,
    List<Song>? featuredSongs,
    List<Song>? filteredSongs,
    String? selectedCategory,
    String? error,
    int? currentPage,
    bool? hasReachedMax,
    int? totalSongs,
    String? searchQuery,
    List<Song>? searchResults,
    String? sortBy,
    bool? sortDescending,
  }) {
    return SongsState(
      status: status ?? this.status,
      songs: songs ?? this.songs,
      featuredSongs: featuredSongs ?? this.featuredSongs,
      filteredSongs: filteredSongs ?? this.filteredSongs,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      totalSongs: totalSongs ?? this.totalSongs,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }

  @override
  List<Object> get props => [
    status, 
    songs, 
    featuredSongs, 
    filteredSongs, 
    selectedCategory, 
    error,
    currentPage,
    hasReachedMax,
    totalSongs,
    searchQuery,
    searchResults,
    sortBy,
    sortDescending,
  ];
}
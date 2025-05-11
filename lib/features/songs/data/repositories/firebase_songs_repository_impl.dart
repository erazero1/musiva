import 'dart:async';
import 'package:musiva/core/utils/exception_handler.dart';
import 'package:musiva/core/utils/logger.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/songs_repository.dart';
import '../datasources/firebase_database_datasource.dart';

class FirebaseSongsRepositoryImpl implements SongsRepository {
  final FirebaseDatabaseDataSource _dataSource;
  static const String _tag = 'FirebaseSongsRepositoryImpl';
  
  FirebaseSongsRepositoryImpl(this._dataSource);
  
  @override
  Future<List<Song>> getSongs({
    int page = 1,
    String? sortBy,
    bool descending = true,
    String? searchQuery,
  }) async {
    log.i('$_tag: Getting songs - page: $page, sortBy: $sortBy, descending: $descending, searchQuery: $searchQuery');
    
    final result = await ExceptionHandler.safeCall(() async {
      final songsData = await _dataSource.getSongs(
        page: page,
        sortBy: sortBy,
        descending: descending,
        searchQuery: searchQuery,
      );
      
      log.d('$_tag: Mapping ${songsData.length} songs from data source');
      return songsData.map((songData) => _mapToSong(songData)).toList();
    });
    
    if (result.isSuccess) {
      log.i('$_tag: Successfully retrieved ${result.data!.length} songs');
      return result.data!;
    } else {
      log.w('$_tag: Failed to get songs: ${result.error}');
      return [];
    }
  }
  
  @override
  Future<List<Song>> getFeaturedSongs() async {
    log.i('$_tag: Getting featured songs');
    
    final result = await ExceptionHandler.safeCall(() async {
      final featuredSongsData = await _dataSource.getFeaturedSongs();
      log.d('$_tag: Mapping ${featuredSongsData.length} featured songs from data source');
      return featuredSongsData.map((songData) => _mapToSong(songData)).toList();
    });
    
    if (result.isSuccess) {
      log.i('$_tag: Successfully retrieved ${result.data!.length} featured songs');
      return result.data!;
    } else {
      log.w('$_tag: Failed to get featured songs: ${result.error}');
      return [];
    }
  }
  
  @override
  Future<int> getTotalSongs() async {
    log.i('$_tag: Getting total songs count');
    
    final result = await ExceptionHandler.safeCall(() async {
      return await _dataSource.getTotalSongs();
    });
    
    if (result.isSuccess) {
      log.i('$_tag: Total songs count: ${result.data}');
      return result.data!;
    } else {
      log.w('$_tag: Failed to get total songs count: ${result.error}');
      return 0;
    }
  }
  
  @override
  Future<void> incrementPlayCount(String songId) async {
    log.i('$_tag: Incrementing play count for song ID: $songId');
    
    final result = await ExceptionHandler.safeCall(() async {
      await _dataSource.incrementPlayCount(songId);
      return true;
    });
    
    if (!result.isSuccess) {
      log.w('$_tag: Failed to increment play count: ${result.error}');
      // Silently fail - this is not critical functionality
    }
  }
  
  @override
  Future<List<Song>> searchSongs(String query) async {
    log.i('$_tag: Searching songs with query: $query');
    
    final result = await ExceptionHandler.safeCall(() async {
      final searchResults = await _dataSource.searchSongs(query);
      log.d('$_tag: Mapping ${searchResults.length} search results from data source');
      return searchResults.map((songData) => _mapToSong(songData)).toList();
    });
    
    if (result.isSuccess) {
      log.i('$_tag: Successfully retrieved ${result.data!.length} search results');
      return result.data!;
    } else {
      log.w('$_tag: Failed to search songs: ${result.error}');
      return [];
    }
  }
  
  // Helper method to convert Map to Song entity
  Song _mapToSong(Map<String, dynamic> data) {
    try {
      log.d('$_tag: Mapping song data for ID: ${data['id']}');
      
      // Handle potential null or invalid values
      final String id = data['id'] ?? '';
      final String title = data['title'] ?? 'Unknown Title';
      final String artist = data['artist'] ?? 'Unknown Artist';
      final String artworkUrl = data['artworkUrl'] ?? '';
      
      // Handle duration
      int durationSeconds = 0;
      if (data['duration'] is int) {
        durationSeconds = data['duration'];
      } else if (data['duration'] is String) {
        durationSeconds = int.tryParse(data['duration']) ?? 0;
      }
      
      // Handle audioUrl
      final String audioUrl = data['audioUrl'] ?? '';
      
      // Handle createdAt
      DateTime createdAt;
      try {
        createdAt = data['createdAt'] != null 
            ? DateTime.parse(data['createdAt']) 
            : DateTime.now();
      } catch (e, stackTrace) {
        log.w('$_tag: Error parsing createdAt date: ${e.toString()}', e, stackTrace);
        createdAt = DateTime.now();
      }
      
      // Handle plays
      int plays = 0;
      if (data['plays'] is int) {
        plays = data['plays'];
      } else if (data['plays'] is String) {
        plays = int.tryParse(data['plays']) ?? 0;
      }
      
      return Song(
        id: id,
        title: title,
        artist: artist,
        artworkUrl: artworkUrl,
        duration: Duration(seconds: durationSeconds),
        audioUrl: audioUrl,
        createdAt: createdAt,
        plays: plays,
      );
    } catch (e, stackTrace) {
      log.e('$_tag: Error mapping song data: ${e.toString()}', e, stackTrace);
      // Return a placeholder song in case of mapping errors
      return Song(
        id: data['id'] ?? 'unknown',
        title: 'Error Loading Song',
        artist: 'Unknown',
        artworkUrl: '',
        duration: const Duration(seconds: 0),
        audioUrl: '',
        createdAt: DateTime.now(),
        plays: 0,
      );
    }
  }
}
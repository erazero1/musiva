import '../entities/song.dart';

abstract class SongsRepository {
  Future<List<Song>> getSongs({
    int page = 1,
    String? sortBy,
    bool descending = true,
    String? searchQuery,
  });
  
  Future<List<Song>> getFeaturedSongs();
  
  Future<int> getTotalSongs();
  
  Future<void> incrementPlayCount(String songId);
  
  Future<List<Song>> searchSongs(String query);
}
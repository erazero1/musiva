import '../entities/song.dart';

abstract class SongsRepository {
  Future<List<Song>> getSongs();
  Future<List<Song>> getFeaturedSongs();
}
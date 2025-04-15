import '../entities/song.dart';

abstract class SongRepository {
  Future<Song> uploadSong(String filePath, Map<String, dynamic> songInfo);
  Future<List<Song>> getSongs();
}
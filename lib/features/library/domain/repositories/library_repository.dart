import '../entities/playlist.dart';
import '../../../songs/domain/entities/song.dart';

abstract class LibraryRepository {
  Future<List<Song>> getRecentSongs();
  Future<List<Playlist>> getPlaylists();
  Future<List<Song>> getFavoriteSongs();
  Future<List<Song>> getDownloadedSongs();
}

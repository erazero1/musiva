import '../../domain/entities/playlist.dart';
import '../../domain/repositories/library_repository.dart';
import '../../../songs/domain/entities/song.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  @override
  Future<List<Song>> getRecentSongs() async {

    // TODO: Implement fetch from network func
    return List.generate(
      8,
      (index) => Song(
        id: 'recent_$index',
        title: 'Recent Song ${index + 1}',
        artist: 'Artist ${(index % 4) + 1}',
        artworkUrl: 'https://picsum.photos/200/200?random=${index + 200}',
        duration: Duration(minutes: 2, seconds: (index * 19) % 60),
        audioUrl: 'https://example.com/songs/recent_$index.mp3',
        createdAt: DateTime.now().subtract(Duration(hours: index * 2)),
        plays: 100 - (index * 10),
      ),
    );
  }

  @override
  Future<List<Playlist>> getPlaylists() async {

    // TODO: Implement fetch from network func
    return List.generate(
      5,
      (index) => Playlist(
        id: 'playlist_$index',
        name: index == 0 ? 'Favorites' : 'Playlist ${index}',
        coverUrl: 'https://picsum.photos/200/200?random=${index + 300}',
        songCount: (index + 1) * 5,
        songIds: List.generate((index + 1) * 5, (i) => 'song_$i'),
      ),
    );
  }

  @override
  Future<List<Song>> getFavoriteSongs() async {

    // TODO: Implement fetch from network func
    return List.generate(
      10,
      (index) => Song(
        id: 'favorite_$index',
        title: 'Favorite Song ${index + 1}',
        artist: 'Artist ${(index % 6) + 1}',
        artworkUrl: 'https://picsum.photos/200/200?random=${index + 400}',
        duration: Duration(minutes: 3, seconds: (index * 13) % 60),
        audioUrl: 'https://example.com/songs/favorite_$index.mp3',
        createdAt: DateTime.now().subtract(Duration(days: index * 3)),
        plays: 500 - (index * 30),
      ),
    );
  }

  @override
  Future<List<Song>> getDownloadedSongs() async {
    // TODO: Implement fetch from network func
    return List.generate(
      7,
      (index) => Song(
        id: 'download_$index',
        title: 'Downloaded Song ${index + 1}',
        artist: 'Artist ${(index % 4) + 1}',
        artworkUrl: 'https://picsum.photos/200/200?random=${index + 500}',
        duration: Duration(minutes: 4, seconds: (index * 11) % 60),
        audioUrl: 'https://example.com/songs/download_$index.mp3',
        createdAt: DateTime.now().subtract(Duration(days: index * 2)),
        plays: 200 - (index * 20),
      ),
    );
  }
}

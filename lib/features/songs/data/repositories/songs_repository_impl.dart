import '../../domain/entities/song.dart';
import '../../domain/repositories/songs_repository.dart';

class SongsRepositoryImpl implements SongsRepository {
  @override
  Future<List<Song>> getSongs() async {
    // TODO: Implement fetch from network func
    await Future.delayed(const Duration(seconds: 1));

    return List.generate(
      20,
      (index) => Song(
        id: 'song_$index',
        title: 'Song ${index + 1}',
        artist: 'Artist ${(index % 5) + 1}',
        artworkUrl: 'https://picsum.photos/200/200?random=$index',
        duration: Duration(minutes: 3, seconds: (index * 17) % 60),
        audioUrl: 'https://example.com/songs/song_$index.mp3',
        createdAt: DateTime.now().subtract(Duration(days: index)),
        plays: 1000 - (index * 50),
      ),
    );
  }

  @override
  Future<List<Song>> getFeaturedSongs() async {
    // TODO: Implement fetch from network func
    await Future.delayed(const Duration(seconds: 1));

    return List.generate(
      5,
      (index) => Song(
        id: 'featured_$index',
        title: 'Featured Track ${index + 1}',
        artist: 'Featured Artist ${(index % 3) + 1}',
        artworkUrl: 'https://picsum.photos/400/400?random=${index + 100}',
        duration: Duration(minutes: 3, seconds: (index * 23) % 60),
        audioUrl: 'https://example.com/songs/featured_$index.mp3',
        createdAt: DateTime.now().subtract(Duration(days: index)),
        plays: 5000 - (index * 300),
      ),
    );
  }
}

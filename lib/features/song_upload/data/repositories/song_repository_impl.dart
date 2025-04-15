import '../../domain/entities/song.dart';
import '../../domain/repositories/song_repository.dart';
import '../datasources/cloudinary_datasource.dart';

class SongRepositoryImpl implements SongRepository {
  final CloudinaryDataSource dataSource;

  SongRepositoryImpl(this.dataSource);

  @override
  Future<Song> uploadSong(String filePath, Map<String, dynamic> songInfo) async {
    final songData = await dataSource.uploadMusicFile(filePath, songInfo);
    return Song.fromJson(songData);
  }

  @override
  Future<List<Song>> getSongs() {
    // Implementation to fetch songs from database or storage
    throw UnimplementedError();
  }
}

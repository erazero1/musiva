import '../entities/song.dart';
import '../repositories/song_repository.dart';

class UploadSongUseCase {
  final SongRepository repository;

  UploadSongUseCase(this.repository);

  Future<Song> call(String filePath, Map<String, dynamic> songInfo) {
    return repository.uploadSong(filePath, songInfo);
  }
}
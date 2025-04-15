part of 'song_upload_bloc.dart';

abstract class SongUploadEvent {}

class SelectAudioFile extends SongUploadEvent {
  final String filePath;
  SelectAudioFile(this.filePath);
}

class UpdateSongInfo extends SongUploadEvent {
  final Map<String, dynamic> songInfo;
  UpdateSongInfo(this.songInfo);
}

class UploadSong extends SongUploadEvent {}


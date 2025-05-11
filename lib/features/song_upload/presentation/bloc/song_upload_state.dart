part of 'song_upload_bloc.dart';
abstract class SongUploadState {}

class SongUploadInitial extends SongUploadState {}

class AudioFileSelected extends SongUploadState {
  final String filePath;
  final String fileName;
  final Map<String, dynamic> metadata;
  
  AudioFileSelected(this.filePath, this.fileName, [this.metadata = const {}]);
  
  bool get hasMetadata => metadata.isNotEmpty;
}

class SongInfoUpdated extends SongUploadState {
  final String filePath;
  final String fileName;
  final Map<String, dynamic> songInfo;
  SongInfoUpdated(this.filePath, this.fileName, this.songInfo);
}

class SongUploading extends SongUploadState {}

class SongUploadSuccess extends SongUploadState {
  final Song song;
  SongUploadSuccess(this.song);
}

class SongUploadFailure extends SongUploadState {
  final String message;
  SongUploadFailure(this.message);
}
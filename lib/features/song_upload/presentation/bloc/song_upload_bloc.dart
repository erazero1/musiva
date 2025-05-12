import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../domain/entities/song.dart';
import 'package:path/path.dart' as path;

import '../../domain/usecases/upload_song_usecase.dart';
part 'song_upload_event.dart';
part 'song_upload_state.dart';

class SongUploadBloc extends Bloc<SongUploadEvent, SongUploadState> {
  final UploadSongUseCase uploadSongUseCase;
  String? _filePath;
  Map<String, dynamic> _songInfo = {};

  SongUploadBloc(this.uploadSongUseCase) : super(SongUploadInitial()) {
    on<SelectAudioFile>(_onSelectAudioFile);
    on<UpdateSongInfo>(_onUpdateSongInfo);
    on<UploadSong>(_onUploadSong);
  }

  FutureOr<void> _onSelectAudioFile(SelectAudioFile event, Emitter<SongUploadState> emit) {
    _filePath = event.filePath;
    final fileName = path.basename(event.filePath);
    emit(AudioFileSelected(event.filePath, fileName));
  }

  FutureOr<void> _onUpdateSongInfo(UpdateSongInfo event, Emitter<SongUploadState> emit) {
    if (_filePath == null) return null;

    _songInfo = event.songInfo;
    final fileName = path.basename(_filePath!);
    emit(SongInfoUpdated(_filePath!, fileName, _songInfo));
  }

  FutureOr<void> _onUploadSong(UploadSong event, Emitter<SongUploadState> emit) async {
    if (_filePath == null) return;

    try {
      emit(SongUploading());
      final song = await uploadSongUseCase(_filePath!, _songInfo);
      emit(SongUploadSuccess(song));
    } catch (e) {
      emit(SongUploadFailure(e.toString()));
    }
  }
}

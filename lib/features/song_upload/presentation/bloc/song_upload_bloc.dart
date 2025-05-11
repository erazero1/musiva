import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:musiva/core/utils/exception_handler.dart';
import 'package:musiva/core/utils/logger.dart';
import '../../domain/entities/song.dart';
import 'package:path/path.dart' as path;

import '../../domain/usecases/upload_song_usecase.dart';
part 'song_upload_event.dart';
part 'song_upload_state.dart';

class SongUploadBloc extends Bloc<SongUploadEvent, SongUploadState> {
  final UploadSongUseCase uploadSongUseCase;
  String? _filePath;
  Map<String, dynamic> _songInfo = {};
  static const String _tag = 'SongUploadBloc';
  final BuildContext? context;
  AppLocalizations? _localizations;

  SongUploadBloc(this.uploadSongUseCase, {this.context}) : super(SongUploadInitial()) {
    if (context != null) {
      _localizations = AppLocalizations.of(context!);
    }
    on<SelectAudioFile>(_onSelectAudioFile);
    on<UpdateSongInfo>(_onUpdateSongInfo);
    on<UploadSong>(_onUploadSong);
  }

  // Helper method to get localized string or fallback to default
  String _getLocalizedString(String key, Map<String, String> params) {
    if (_localizations == null) return key;
    
    switch (key) {
      case 'file_not_exist_error':
        return _localizations!.file_not_exist_error(params['filePath'] ?? '');
      case 'invalid_file_format_error':
        return _localizations!.invalid_file_format_error;
      case 'file_too_large_error':
        return _localizations!.file_too_large_error;
      case 'metadata_extraction_error':
        return _localizations!.metadata_extraction_error(params['error'] ?? '');
      case 'audio_file_selection_error':
        return _localizations!.audio_file_selection_error(params['error'] ?? '');
      case 'no_audio_file_selected_error':
        return _localizations!.no_audio_file_selected_error;
      case 'song_title_empty_error':
        return _localizations!.song_title_empty_error;
      case 'artist_name_empty_error':
        return _localizations!.artist_name_empty_error;
      case 'song_info_update_error':
        return _localizations!.song_info_update_error(params['error'] ?? '');
      case 'song_info_incomplete_error':
        return _localizations!.song_info_incomplete_error;
      case 'song_upload_error':
        return _localizations!.song_upload_error(params['error'] ?? '');
      case 'using_embedded_artwork':
        return _localizations!.using_embedded_artwork;
      default:
        return key;
    }
  }

  FutureOr<void> _onSelectAudioFile(SelectAudioFile event, Emitter<SongUploadState> emit) async {
    try {
      final filePath = event.filePath;
      log.i('$_tag: Audio file selected: $filePath');
      
      // Validate file exists
      final file = File(filePath);
      if (!file.existsSync()) {
        final errorMsg = _getLocalizedString('file_not_exist_error', {'filePath': filePath});
        log.e('$_tag: $errorMsg');
        emit(SongUploadFailure(errorMsg));
        return;
      }
      
      // Validate file extension
      final extension = path.extension(filePath).toLowerCase();
      if (extension != '.mp3') {
        final errorMsg = _getLocalizedString('invalid_file_format_error', {});
        log.e('$_tag: $errorMsg - File extension: $extension');
        emit(SongUploadFailure(errorMsg));
        return;
      }
      
      // Validate file size (max 20MB)
      final fileSize = file.lengthSync();
      final maxSize = 20 * 1024 * 1024; // 20MB in bytes
      if (fileSize > maxSize) {
        final errorMsg = _getLocalizedString('file_too_large_error', {});
        log.e('$_tag: $errorMsg - File size: ${fileSize / (1024 * 1024)}MB');
        emit(SongUploadFailure(errorMsg));
        return;
      }
      
      _filePath = filePath;
      final fileName = path.basename(filePath);
      log.d('$_tag: File name: $fileName');
      
      // Extract metadata from the audio file
      Map<String, dynamic> metadata = {};
      try {
        final metadataResult = await MetadataGod.readMetadata(file: file.path);
        log.d('$_tag: Metadata extracted: ${metadataResult.toString()}');
        
        if (metadataResult.title != null && metadataResult.title!.isNotEmpty) {
          metadata['title'] = metadataResult.title;
        }
        
        if (metadataResult.artist != null && metadataResult.artist!.isNotEmpty) {
          metadata['artist'] = metadataResult.artist;
        }
        
        // If there's album art in the metadata
        if (metadataResult.picture != null) {
          // We'll handle this in the UI to display the embedded artwork
          metadata['hasPicture'] = true;
          metadata['picture'] = metadataResult.picture;
        } else {
          metadata['hasPicture'] = false;
        }
        
        log.i('$_tag: Metadata extracted successfully: $metadata');
      } catch (e, stackTrace) {
        // Just log the error but continue with the file selection
        log.w('$_tag: Error extracting metadata: ${e.toString()}', e, stackTrace);
        metadata['error'] = _getLocalizedString('metadata_extraction_error', {'error': e.toString()});
      }
      
      emit(AudioFileSelected(filePath, fileName, metadata));
      log.i('$_tag: Audio file selection successful');
    } catch (e, stackTrace) {
      final errorMsg = _getLocalizedString('audio_file_selection_error', {'error': e.toString()});
      log.e('$_tag: $errorMsg', e, stackTrace);
      emit(SongUploadFailure(errorMsg));
    }
  }

  FutureOr<void> _onUpdateSongInfo(UpdateSongInfo event, Emitter<SongUploadState> emit) {
    try {
      log.i('$_tag: Updating song info');
      
      if (_filePath == null) {
        final errorMsg = _getLocalizedString('no_audio_file_selected_error', {});
        log.e('$_tag: $errorMsg');
        emit(SongUploadFailure(errorMsg));
        return null;
      }

      // Validate required fields
      final songInfo = event.songInfo;
      if (songInfo['title'] == null || songInfo['title'].isEmpty) {
        final errorMsg = _getLocalizedString('song_title_empty_error', {});
        log.e('$_tag: $errorMsg');
        emit(SongUploadFailure(errorMsg));
        return null;
      }
      
      if (songInfo['artist'] == null || songInfo['artist'].isEmpty) {
        final errorMsg = _getLocalizedString('artist_name_empty_error', {});
        log.e('$_tag: $errorMsg');
        emit(SongUploadFailure(errorMsg));
        return null;
      }
      
      _songInfo = songInfo;
      final fileName = path.basename(_filePath!);
      
      log.d('$_tag: Song info updated - Title: ${songInfo['title']}, Artist: ${songInfo['artist']}');
      emit(SongInfoUpdated(_filePath!, fileName, _songInfo));
      log.i('$_tag: Song info update successful');
    } catch (e, stackTrace) {
      final errorMsg = _getLocalizedString('song_info_update_error', {'error': e.toString()});
      log.e('$_tag: $errorMsg', e, stackTrace);
      emit(SongUploadFailure(errorMsg));
    }
  }

  FutureOr<void> _onUploadSong(UploadSong event, Emitter<SongUploadState> emit) async {
    try {
      log.i('$_tag: Starting song upload process');
      
      if (_filePath == null) {
        final errorMsg = _getLocalizedString('no_audio_file_selected_error', {});
        log.e('$_tag: $errorMsg');
        emit(SongUploadFailure(errorMsg));
        return;
      }
      
      // Validate song info again
      if (_songInfo.isEmpty || _songInfo['title'] == null || _songInfo['title'].isEmpty) {
        final errorMsg = _getLocalizedString('song_info_incomplete_error', {});
        log.e('$_tag: $errorMsg');
        emit(SongUploadFailure(errorMsg));
        return;
      }

      emit(SongUploading());
      log.d('$_tag: Emitted SongUploading state');
      
      // If we have embedded artwork from metadata and no artwork file or URL is provided,
      // we can use the embedded artwork
      final currentState = state;
      if (currentState is AudioFileSelected && 
          currentState.metadata['hasPicture'] == true &&
          !_songInfo.containsKey('artworkFilePath') && 
          (!_songInfo.containsKey('artworkUrl') || _songInfo['artworkUrl'].isEmpty)) {
        
        log.i('$_tag: ${_getLocalizedString('using_embedded_artwork', {})}');
        
        // In a real implementation, we would save the embedded artwork to a temporary file
        // and then use that file path in the song info
        // For now, we'll just log this information
        log.d('$_tag: Embedded artwork would be used here in a complete implementation');
        
        // This is where you would implement saving the embedded artwork to a file
        // _songInfo['artworkFilePath'] = savedArtworkFilePath;
      } else if (!_songInfo.containsKey('artworkFilePath') && 
                (!_songInfo.containsKey('artworkUrl') || _songInfo['artworkUrl'].isEmpty)) {
        // No artwork provided - we'll use the default placeholder
        log.i('$_tag: No artwork provided, will use default placeholder');
      }
      
      log.d('$_tag: Calling upload song use case with file: $_filePath');
      final result = await ExceptionHandler.safeCall(() async {
        return await uploadSongUseCase(_filePath!, _songInfo);
      });
      
      if (result.isSuccess) {
        final song = result.data!;
        log.i('$_tag: Song uploaded successfully - ID: ${song.id}, Title: ${song.title}');
        emit(SongUploadSuccess(song));
      } else {
        log.e('$_tag: Song upload failed: ${result.error}');
        emit(SongUploadFailure(result.error!));
      }
    } catch (e, stackTrace) {
      final errorMsg = _getLocalizedString('song_upload_error', {'error': e.toString()});
      log.e('$_tag: $errorMsg', e, stackTrace);
      emit(SongUploadFailure(errorMsg));
    }
  }
}

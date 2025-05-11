import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musiva/core/utils/exception_handler.dart';
import 'package:musiva/core/utils/logger.dart';
import 'package:musiva/features/song_upload/data/datasources/firebase_storage_datasource.dart';

import '../../domain/entities/song.dart';
import '../../domain/repositories/song_repository.dart';

class SongRepositoryImpl implements SongRepository {
  final FirebaseStorageDataSource dataSource;
  static const String _tag = 'SongRepositoryImpl';
  final BuildContext? context;
  AppLocalizations? _localizations;

  SongRepositoryImpl(this.dataSource, {this.context}) {
    if (context != null) {
      _localizations = AppLocalizations.of(context!);
    }
  }

  // Helper method to get localized string or fallback to default
  String _getLocalizedString(String key, Map<String, String> params) {
    if (_localizations == null) return key;
    
    switch (key) {
      case 'file_path_empty_error':
        return _localizations!.file_path_empty_error;
      case 'song_title_empty_error':
        return _localizations!.song_title_empty_error;
      case 'artist_name_empty_error':
        return _localizations!.artist_name_empty_error;
      case 'failed_to_upload_song_error':
        return _localizations!.failed_to_upload_song_error(params['error'] ?? '');
      case 'songs_not_implemented_error':
        return _localizations!.songs_not_implemented_error;
      default:
        return key;
    }
  }

  @override
  Future<Song> uploadSong(String filePath, Map<String, dynamic> songInfo) async {
    log.i('$_tag: Uploading song from file: $filePath');
    
    try {
      // Validate inputs
      if (filePath.isEmpty) {
        final errorMsg = _getLocalizedString('file_path_empty_error', {});
        log.e('$_tag: $errorMsg');
        throw Exception(errorMsg);
      }
      
      if (songInfo['title'] == null || songInfo['title'].isEmpty) {
        final errorMsg = _getLocalizedString('song_title_empty_error', {});
        log.e('$_tag: $errorMsg');
        throw Exception(errorMsg);
      }
      
      if (songInfo['artist'] == null || songInfo['artist'].isEmpty) {
        final errorMsg = _getLocalizedString('artist_name_empty_error', {});
        log.e('$_tag: $errorMsg');
        throw Exception(errorMsg);
      }
      
      log.d('$_tag: Input validation passed, proceeding with upload');
      
      final songData = await dataSource.uploadSong(filePath, songInfo);
      log.i('$_tag: Song uploaded successfully, mapping to entity');
      
      final song = Song.fromJson(songData);
      log.d('$_tag: Song entity created: ${song.title} by ${song.artist}');
      
      return song;
    } catch (e, stackTrace) {
      final errorMsg = _getLocalizedString('failed_to_upload_song_error', {'error': e.toString()});
      log.e('$_tag: $errorMsg', e, stackTrace);
      throw Exception(errorMsg);
    }
  }

  @override
  Future<List<Song>> getSongs() async {
    final errorMsg = _getLocalizedString('songs_not_implemented_error', {});
    log.w('$_tag: $errorMsg');
    throw UnimplementedError(errorMsg);
  }
}

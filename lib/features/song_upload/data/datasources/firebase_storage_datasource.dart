import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musiva/core/utils/exception_handler.dart';
import 'package:musiva/core/utils/logger.dart';
import 'package:musiva/core/utils/retry_helper.dart';
import 'package:musiva/features/song_upload/domain/entities/song.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class FirebaseStorageDataSource {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  static const String _tag = 'FirebaseStorageDataSource';
  final BuildContext? context;
  AppLocalizations? _localizations;

  FirebaseStorageDataSource({this.context}) {
    if (context != null) {
      _localizations = AppLocalizations.of(context!);
    }
  }

  // Helper method to get localized string or fallback to default
  String _getLocalizedString(String key, Map<String, String> params) {
    if (_localizations == null) return key;
    
    switch (key) {
      case 'song_file_not_exist_error':
        return _localizations!.song_file_not_exist_error(params['filePath'] ?? '');
      case 'failed_to_upload_song_error':
        return _localizations!.failed_to_upload_song_error(params['error'] ?? '');
      default:
        return key;
    }
  }

  Future<Map<String, dynamic>> uploadSong(String filePath, Map<String, dynamic> songInfo) async {
    try {
      log.i('$_tag: Starting song upload process');
      final String id = const Uuid().v4();
      log.d('$_tag: Generated song ID: $id');
      
      // Get song duration
      log.d('$_tag: Getting song duration from file: $filePath');
      final songFile = File(filePath);
      
      if (!songFile.existsSync()) {
        final errorMsg = _getLocalizedString('song_file_not_exist_error', {'filePath': filePath});
        log.e('$_tag: $errorMsg');
        throw Exception(errorMsg);
      }
      
      final audioPlayer = AudioPlayer();
      try {
        await audioPlayer.setFilePath(filePath);
        final duration = audioPlayer.duration ?? const Duration(seconds: 0);
        log.d('$_tag: Song duration: ${duration.inSeconds} seconds');
        await audioPlayer.dispose();
        
        // Upload song file to Firebase Storage with retry mechanism
        final songFileName = '$id${path.extension(filePath)}';
        log.i('$_tag: Uploading song file to Firebase Storage: songs/$songFileName');
        final songRef = _storage.ref().child("songs/$songFileName");
        
        final metadata = SettableMetadata(
          contentType: 'audio/mpeg',
          customMetadata: {
            'title': songInfo['title'],
            'artist': songInfo['artist'],
            'duration': duration.inSeconds.toString(),
          },
        );
        
        // Use retry mechanism for song upload
        String songUrl = await RetryHelper.retry(
          operation: () async {
            // Track upload progress
            final uploadTask = songRef.putFile(songFile, metadata);
            uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
              final progress = snapshot.bytesTransferred / snapshot.totalBytes;
              log.d('$_tag: Song upload progress: ${(progress * 100).toStringAsFixed(2)}%');
            });
            
            // Wait for upload to complete
            await uploadTask;
            log.i('$_tag: Song file uploaded successfully');
            
            // Get download URL
            return await songRef.getDownloadURL();
          },
          maxRetries: 3,
          retryDelay: 2000,
          onRetry: (exception, attempt, maxAttempts) {
            log.w('$_tag: Retrying song upload (attempt $attempt/$maxAttempts) after error: ${exception.toString()}');
          },
        );
        
        log.d('$_tag: Song download URL: $songUrl');
        
        // Handle artwork - either from URL, uploaded file, or use default placeholder
        String artworkUrl = '';
        
        if (songInfo['artworkFilePath'] != null) {
          final artworkPath = songInfo['artworkFilePath'];
          log.d('$_tag: Uploading artwork from file: $artworkPath');
          
          final artworkFile = File(artworkPath);
          if (!artworkFile.existsSync()) {
            log.w('$_tag: Artwork file does not exist at path: $artworkPath');
            // Will use default placeholder instead
            artworkUrl = await _getDefaultPlaceholderUrl(id);
            log.d('$_tag: Using default placeholder image for artwork');
          } else {
            // Use retry mechanism for artwork upload
            artworkUrl = await RetryHelper.retry(
              operation: () async {
                final artworkFileName = '${id}_cover${path.extension(artworkPath)}';
                final artworkRef = _storage.ref().child("songs/covers/$artworkFileName");
                
                final artworkMetadata = SettableMetadata(
                  contentType: _getContentType(artworkPath),
                );
                
                // Track upload progress
                final artworkUploadTask = artworkRef.putFile(artworkFile, artworkMetadata);
                artworkUploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
                  final progress = snapshot.bytesTransferred / snapshot.totalBytes;
                  log.d('$_tag: Artwork upload progress: ${(progress * 100).toStringAsFixed(2)}%');
                });
                
                await artworkUploadTask;
                log.i('$_tag: Artwork file uploaded successfully');
                
                return await artworkRef.getDownloadURL();
              },
              maxRetries: 3,
              retryDelay: 1500,
              onRetry: (exception, attempt, maxAttempts) {
                log.w('$_tag: Retrying artwork upload (attempt $attempt/$maxAttempts) after error: ${exception.toString()}');
              },
            );
            
            log.d('$_tag: Artwork download URL: $artworkUrl');
          }
        } else if (songInfo['artworkUrl'] != null && songInfo['artworkUrl'].isNotEmpty) {
          // Use the provided URL
          artworkUrl = songInfo['artworkUrl'];
          log.d('$_tag: Using provided artwork URL: $artworkUrl');
        } else {
          // Use default placeholder image from assets
          log.d('$_tag: Using default placeholder image for artwork');
          
          // Get the URL for the default placeholder image
          artworkUrl = await _getDefaultPlaceholderUrl(id);
          log.i('$_tag: Using default placeholder image: $artworkUrl');
        }

        // Create song data
        final songData = {
          'id': id,
          'title': songInfo['title'],
          'artist': songInfo['artist'],
          'artworkUrl': artworkUrl,
          'duration': duration.inSeconds,
          'audioUrl': songUrl,
          'createdAt': DateTime.now().toIso8601String(),
          'plays': 0,
        };
        
        // Save to Firebase Realtime Database with retry
        log.i('$_tag: Saving song data to Firebase Realtime Database');
        await RetryHelper.retry(
          operation: () => _database.ref().child('songs').child(id).set(songData),
          maxRetries: 3,
          retryDelay: 1000,
          onRetry: (exception, attempt, maxAttempts) {
            log.w('$_tag: Retrying database save (attempt $attempt/$maxAttempts) after error: ${exception.toString()}');
          },
        );
        
        log.i('$_tag: Song data saved successfully');

        return songData;
      } finally {
        // Ensure audio player is disposed
        if (audioPlayer.playing) {
          await audioPlayer.stop();
        }
        await audioPlayer.dispose();
        log.d('$_tag: Audio player disposed');
      }
    } catch (e, stackTrace) {
      final errorMsg = _getLocalizedString('failed_to_upload_song_error', {'error': e.toString()});
      log.e('$_tag: $errorMsg', e, stackTrace);
      throw Exception(errorMsg);
    }
  }
  
  // Helper method to determine content type based on file extension
  String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.bmp':
        return 'image/bmp';
      default:
        log.w('$_tag: Unknown file extension for content type: $extension, defaulting to image/jpeg');
        return 'image/jpeg';
    }
  }

  Future<String> _getDefaultPlaceholderUrl(String songId) async {
    try {
      log.d('$_tag: Getting default placeholder URL for song ID: $songId');
      return 'https://firebasestorage.googleapis.com/v0/b/musiva-f0e54.firebasestorage.app/o/songs%2Fcovers%2Fplaceholder_album.jpg?alt=media&token=f8946a91-1930-418e-8cb2-f95ed8092a2a';
    } catch (e, stackTrace) {
      log.w('$_tag: Error getting default placeholder URL: ${e.toString()}', e, stackTrace);
      return 'assets/placeholder_album.jpg';
    }
  }
}
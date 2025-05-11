import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musiva/features/song_upload/domain/entities/song.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class FirebaseStorageDataSource {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<Map<String, dynamic>> uploadSong(String filePath, Map<String, dynamic> songInfo) async {
    final String id = const Uuid().v4();
    
    // Get song duration
    final songFile = File(filePath);
    final audioPlayer = AudioPlayer();
    await audioPlayer.setFilePath(filePath);
    final duration = audioPlayer.duration ?? const Duration(seconds: 0);
    await audioPlayer.dispose();
    
    // Upload song file to Firebase Storage
    final songFileName = '$id${path.extension(filePath)}';
    final songRef = _storage.ref().child("songs/$songFileName");
    
    await songRef.putFile(songFile, SettableMetadata(
      contentType: 'audio/mpeg',
      customMetadata: {
        'title': songInfo['title'],
        'artist': songInfo['artist'],
        'duration': duration.inSeconds.toString(),
      },
    ));
    final songUrl = await songRef.getDownloadURL();
    
    // Handle artwork - either from URL or uploaded file
    String artworkUrl = '';
    
    if (songInfo['artworkFilePath'] != null) {
      // Upload artwork file to Firebase Storage
      final artworkFile = File(songInfo['artworkFilePath']);
      final artworkFileName = '${id}_cover${path.extension(songInfo['artworkFilePath'])}';
      final artworkRef = _storage.ref().child("songs/covers/$artworkFileName");
      
      await artworkRef.putFile(artworkFile, SettableMetadata(
        contentType: 'image/jpeg', // Adjust based on actual file type if needed
      ));
      
      artworkUrl = await artworkRef.getDownloadURL();
    } else if (songInfo['artworkUrl'] != null && songInfo['artworkUrl'].isNotEmpty) {
      // Use the provided URL
      artworkUrl = songInfo['artworkUrl'];
    }

    return {
      'id': id,
      'title': songInfo['title'],
      'artist': songInfo['artist'],
      'artworkUrl': artworkUrl,
      'duration': duration.inSeconds,
      'audioUrl': songUrl,
      'createdAt': DateTime.now().toIso8601String(),
      'plays': 0,
    };
  }
}
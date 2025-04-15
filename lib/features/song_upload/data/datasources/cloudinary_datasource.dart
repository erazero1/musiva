import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:just_audio/just_audio.dart';

class CloudinaryDataSource {
  final CloudinaryPublic cloudinary;

  CloudinaryDataSource(this.cloudinary);

  Future<Map<String, dynamic>> uploadMusicFile(String filePath, Map<String, dynamic> songInfo) async {
    final String id = const Uuid().v4();
    final String folder = 'songs/$id';

    // Upload the audio file
    final fileName = path.basename(filePath);
    final response = await cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        filePath,
        folder: folder,
        resourceType: CloudinaryResourceType.Auto,
      ),
    );

    // Get the duration of the audio file
    final audioPlayer = AudioPlayer();
    await audioPlayer.setFilePath(filePath);
    final duration = audioPlayer.duration ?? const Duration(seconds: 0);
    await audioPlayer.dispose();

    // Return the song data
    return {
      'id': id,
      'title': songInfo['title'],
      'artist': songInfo['artist'],
      'artworkUrl': songInfo['artworkUrl'] ?? '',
      'duration': duration.inSeconds,
      'audioUrl': response.secureUrl,
      'createdAt': DateTime.now().toIso8601String(),
      'plays': 0,
    };
  }
}
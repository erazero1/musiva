import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/entities/song.dart';
import '../../domain/repositories/songs_repository.dart';

class SongsRepositoryImpl implements SongsRepository {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://api.spotify.com/v1';
  final String _clientId;
  final String _clientSecret;
  String? _accessToken;


  @override
  @override
  Future<List<Song>> getSongs(
      {String query = 'popular', int limit = 20}) async {
    try { 
      _accessToken = await getSpotifyToken(clientId: _clientId, clientSecret: _clientSecret);
      // Search for tracks
      final response = await _dio.get(
        '$_baseUrl/search',
        queryParameters: {'q': query, 'type': 'track', 'limit': limit},
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> items = response.data['tracks']['items'];
        return items.map((item) => _mapToSong(item)).toList();
      } else {
        throw Exception('Failed to load songs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load songs: $e');
    }
  }

  @override
  Future<List<Song>> getFeaturedSongs() async {
    // TODO: Implement fetch from network func

    return List.generate(
      5,
      (index) => Song(
        id: 'featured_$index',
        title: 'Featured Track ${index + 1}',
        artist: 'Featured Artist ${(index % 3) + 1}',
        artworkUrl: 'https://picsum.photos/400/400?random=${index + 100}',
        duration: Duration(minutes: 3, seconds: (index * 23) % 60),
        audioUrl: 'https://example.com/songs/featured_$index.mp3',
        createdAt: DateTime.now().subtract(Duration(days: index)),
        plays: 5000 - (index * 300),
      ),
    );
  }

  Song _mapToSong(Map<String, dynamic> data) {
    // Extract artist names
    final List<dynamic> artists = data['artists'];
    final String artistNames =
        artists.map((artist) => artist['name']).join(', ');

    // Get album artwork (using the first image)
    final List<dynamic> images = data['album']['images'];
    final String artworkUrl = images.isNotEmpty ? images[0]['url'] : '';

    // Convert duration from milliseconds to Duration
    final int durationMs = data['duration_ms'];
    final Duration duration = Duration(milliseconds: durationMs);

    final String audioUrl = data['uri'];

    // For play count and creation date, we'll use some approximations
    // since these aren't directly available in the basic track data
    final int popularity = data['popularity'];
    final int plays =
        popularity * 1000; // Rough approximation based on popularity

    // Using the album release date as an approximation for track creation date
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(data['album']['release_date']);
    } catch (e) {
      createdAt = DateTime.now(); // Fallback if date parsing fails
    }

    return Song(
      id: data['id'],
      title: data['name'],
      artist: artistNames,
      artworkUrl: artworkUrl,
      duration: duration,
      audioUrl: audioUrl,
      createdAt: createdAt,
      plays: plays,
    );
  }
  Future<String> getSpotifyToken({
    required String clientId,
    required String clientSecret,
  }) async {
    final credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));

    try {
      final response = await _dio.post(
        'https://accounts.spotify.com/api/token',
        options: Options(
          headers: {
            'Authorization': 'Basic $credentials',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
        data: {
          'grant_type': 'client_credentials',
        },
      );

      if (response.statusCode == 200) {
        return response.data['access_token'];
      } else {
        throw Exception('Failed to obtain token: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to obtain token: $e');
    }
  }

  SongsRepositoryImpl({
    required String clientId,
    required String clientSecret,
  })
      : _clientId = clientId,
        _clientSecret = clientSecret;
}

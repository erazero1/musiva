class Song {
  final String id;
  final String title;
  final String artist;
  final String artworkUrl;
  final Duration duration;
  final String audioUrl;
  final DateTime createdAt;
  final int plays;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    required this.duration,
    required this.audioUrl,
    required this.createdAt,
    required this.plays,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'artworkUrl': artworkUrl,
      'duration': duration.inSeconds,
      'audioUrl': audioUrl,
      'createdAt': createdAt.toIso8601String(),
      'plays': plays,
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      artworkUrl: json['artworkUrl'],
      duration: Duration(seconds: json['duration']),
      audioUrl: json['audioUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      plays: json['plays'],
    );
  }
}
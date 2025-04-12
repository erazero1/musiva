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
}

class Playlist {
  final String id;
  final String name;
  final String coverUrl;
  final int songCount;
  final List<String> songIds;

  Playlist({
    required this.id,
    required this.name,
    required this.coverUrl,
    required this.songCount,
    required this.songIds,
  });
}
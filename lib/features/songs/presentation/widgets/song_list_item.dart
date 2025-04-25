import 'package:flutter/material.dart';
import '../../domain/entities/song.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SongListItem extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const SongListItem({
    super.key,
    required this.song,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Song thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                song.artworkUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.music_note,
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),

            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Duration
            Text(
              _formatDuration(song.duration),
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 12),

            // More options button
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                _showOptionsBottomSheet(context, song);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showOptionsBottomSheet(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: Text(AppLocalizations.of(context)!.add_to_playlist_label),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Add song to playlist
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: Text(AppLocalizations.of(context)!.add_to_favorites_label),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Add song to favorites
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(AppLocalizations.of(context)!.share_label),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Share song
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: Text(AppLocalizations.of(context)!.download_label),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Download song
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
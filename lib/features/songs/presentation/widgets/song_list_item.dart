import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/song.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musiva/features/player/presentation/bloc/player_bloc.dart';

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
    return Dismissible(
      key: Key('song_${song.id}'),
      direction: DismissDirection.startToEnd,
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Icon(
              Icons.playlist_add,
              color: Colors.green.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)?.add_to_queue_label ?? 'Add to queue',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Add to queue
          context.read<PlayerBloc>().add(AddToQueue(song, playIfEmpty: true));
          
          // Show snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${song.title} ${AppLocalizations.of(context)?.added_to_queue_label ?? 'added to queue'}',
              ),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: AppLocalizations.of(context)?.undo_label ?? 'Undo',
                onPressed: () {
                  // Get the current queue
                  final playerState = context.read<PlayerBloc>().state;
                  final queue = playerState.queue;
                  
                  // Find the index of the song we just added (should be the last one)
                  final index = queue.lastIndexWhere((s) => s.id == song.id);
                  
                  if (index != -1) {
                    context.read<PlayerBloc>().add(RemoveFromQueue(index));
                  }
                },
              ),
            ),
          );
        }
        // Return false to prevent the dismissible from removing the item
        return false;
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withOpacity(0.9), // More opaque background
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2), // Stronger shadow
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.1), // Subtle border
              width: 1,
            ),
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
            ],
          ),
        );
      },
    );
  }
}
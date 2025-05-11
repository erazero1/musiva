import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musiva/features/songs/domain/entities/song.dart';

class QueueList extends StatelessWidget {
  final List<Song> queue;
  final int currentIndex;
  final Function(int) onTap;

  const QueueList({
    super.key,
    required this.queue,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (queue.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.queue_empty_label),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      itemCount: queue.length,
      itemBuilder: (context, index) {
        final song = queue[index];
        final isCurrentSong = index == currentIndex;

        return ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              image: DecorationImage(
                image: NetworkImage(song.artworkUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          title: Text(
            song.title,
            style: TextStyle(
              fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
              color: isCurrentSong ? Theme.of(context).primaryColor : null,
            ),
          ),
          subtitle: Text(song.artist),
          trailing: Text(
            _formatDuration(song.duration),
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          onTap: () => onTap(index),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
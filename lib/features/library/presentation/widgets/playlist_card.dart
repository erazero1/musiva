import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlaylistCard extends StatelessWidget {
  final String? imageUrl;
  final String? title;
  final int? songCount;
  final VoidCallback onTap;
  final bool isCreatePlaylist;

  const PlaylistCard({
    super.key,
    this.imageUrl,
    this.title,
    this.songCount,
    required this.onTap,
    this.isCreatePlaylist = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: isCreatePlaylist
              ? Colors.grey.withOpacity(0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isCreatePlaylist) ...[
              // Create playlist icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  size: 36,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              // Create playlist text
              Text(
                AppLocalizations.of(context)!.create_playlist_label,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ] else ...[
              // Playlist cover
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.playlist_play,
                              color: Colors.white,
                              size: 48,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // Playlist title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  title ?? '',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              // Song count
              Text(
                '$songCount ${AppLocalizations.of(context)!.songs_label}',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

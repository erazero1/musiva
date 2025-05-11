import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musiva/features/player/domain/entities/player_state.dart' as player_entities;
import 'package:musiva/features/player/presentation/bloc/player_bloc.dart';
import 'package:musiva/features/player/presentation/pages/full_player_page.dart';

class NowPlayingMiniPlayer extends StatelessWidget {
  const NowPlayingMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlayerBloc, player_entities.PlayerState>(
      listener: (context, state) {
        // Show a snackbar when there's an error message
        if (state.error != null) {
          // Hide any existing snackbar first to prevent stacking
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          // Then show the new error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'OK',
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  
                  // Clear the error state when user dismisses the snackbar
                  if (state.error != null) {
                    context.read<PlayerBloc>().add(RefreshPlayerState());
                  }
                },
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        // Don't show the mini player if there's no song in the queue
        if (state.currentSong == null) {
          return const SizedBox.shrink();
        }
        
        final currentSong = state.currentSong!;
        final isPlaying = state.playbackState == player_entities.PlaybackState.playing;
        
        return Semantics(
          label: 'Now playing: ${currentSong.title} by ${currentSong.artist}',
          hint: 'Tap to open full player',
          button: true,
          child: GestureDetector(
            onTap: () {
              // Navigate to full player
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FullPlayerPage(),
                ),
              );
            },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Song thumbnail
                Hero(
                  tag: 'album_art_${currentSong.id}',
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      image: DecorationImage(
                        image: NetworkImage(currentSong.artworkUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Song info - increased flex to give more space to text
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentSong.title,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentSong.artist,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Progress indicator - made optional based on available width
                MediaQuery.of(context).size.width > 400 ? 
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RepaintBoundary(
                        child: LinearProgressIndicator(
                          value: state.duration.inMilliseconds > 0
                              ? state.position.inMilliseconds / state.duration.inMilliseconds
                              : 0.0,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                          minHeight: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDuration(state.position),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ) : const SizedBox.shrink(),

                // Playback controls - wrapped in a Row with mainAxisSize.min
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Only show previous/next buttons on wider screens
                    if (MediaQuery.of(context).size.width > 360)
                      Semantics(
                        label: 'Previous song',
                        button: true,
                        enabled: true,
                        child: IconButton(
                          icon: const Icon(Icons.skip_previous),
                          onPressed: () {
                            context.read<PlayerBloc>().add(PreviousSong());
                          },
                          tooltip: 'Previous song',
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    
                    // Always show play/pause button
                    Semantics(
                      label: isPlaying ? 'Pause' : 'Play',
                      button: true,
                      enabled: true,
                      child: IconButton(
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () {
                          if (isPlaying) {
                            context.read<PlayerBloc>().add(PauseSong());
                          } else {
                            context.read<PlayerBloc>().add(ResumeSong());
                          }
                        },
                        tooltip: isPlaying ? 'Pause' : 'Play',
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    
                    // Only show previous/next buttons on wider screens
                    if (MediaQuery.of(context).size.width > 360)
                      Semantics(
                        label: 'Next song',
                        button: true,
                        enabled: true,
                        child: IconButton(
                          icon: const Icon(Icons.skip_next),
                          onPressed: () {
                            context.read<PlayerBloc>().add(NextSong());
                          },
                          tooltip: 'Next song',
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
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

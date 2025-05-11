import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musiva/features/player/domain/entities/player_state.dart';

class PlayerControls extends StatelessWidget {
  final PlaybackState playbackState;
  final RepeatMode repeatMode;
  final bool isShuffled;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onToggleShuffle;
  final Function(RepeatMode) onSetRepeatMode;

  const PlayerControls({
    super.key,
    required this.playbackState,
    required this.repeatMode,
    required this.isShuffled,
    required this.onPlay,
    required this.onPause,
    required this.onNext,
    required this.onPrevious,
    required this.onToggleShuffle,
    required this.onSetRepeatMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous button with accessibility
            Semantics(
              label: AppLocalizations.of(context)!.previous_song_label,
              button: true,
              enabled: true,
              child: IconButton(
                icon: const Icon(Icons.skip_previous),
                iconSize: 40,
                onPressed: onPrevious,
                tooltip: AppLocalizations.of(context)!.previous_song_label,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Play/Pause button with accessibility
            Semantics(
              label: playbackState == PlaybackState.playing ? AppLocalizations.of(context)!.pause_label : AppLocalizations.of(context)!.play_label,
              button: true,
              enabled: true,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor,
                ),
                child: IconButton(
                  icon: Icon(
                    playbackState == PlaybackState.playing
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  iconSize: 40,
                  onPressed: playbackState == PlaybackState.playing ? onPause : onPlay,
                  tooltip: playbackState == PlaybackState.playing ? AppLocalizations.of(context)!.pause_label : AppLocalizations.of(context)!.play_label,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Next button with accessibility
            Semantics(
              label: AppLocalizations.of(context)!.next_song_label,
              button: true,
              enabled: true,
              child: IconButton(
                icon: const Icon(Icons.skip_next),
                iconSize: 40,
                onPressed: onNext,
                tooltip: AppLocalizations.of(context)!.next_song_label,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Secondary controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Shuffle button with accessibility
            Semantics(
              label: isShuffled ? AppLocalizations.of(context)!.shuffle_on_label : AppLocalizations.of(context)!.shuffle_off_label,
              button: true,
              enabled: true,
              child: IconButton(
                icon: Icon(
                  Icons.shuffle,
                  color: isShuffled ? Theme.of(context).primaryColor : null,
                ),
                onPressed: onToggleShuffle,
                tooltip: isShuffled ? AppLocalizations.of(context)!.turn_shuffle_off_label : AppLocalizations.of(context)!.turn_shuffle_on_label,
              ),
            ),
            
            // Repeat button with accessibility
            Semantics(
              label: repeatMode == RepeatMode.off 
                  ? AppLocalizations.of(context)!.repeat_off_label
                  : (repeatMode == RepeatMode.one 
                      ? AppLocalizations.of(context)!.repeat_one_song_label
                      : AppLocalizations.of(context)!.repeat_all_songs_label),
              button: true,
              enabled: true,
              child: IconButton(
                icon: Icon(
                  repeatMode == RepeatMode.one
                      ? Icons.repeat_one
                      : Icons.repeat,
                  color: repeatMode != RepeatMode.off
                      ? Theme.of(context).primaryColor
                      : null,
                ),
                onPressed: () {
                  // Cycle through repeat modes
                  switch (repeatMode) {
                    case RepeatMode.off:
                      onSetRepeatMode(RepeatMode.all);
                      break;
                    case RepeatMode.all:
                      onSetRepeatMode(RepeatMode.one);
                      break;
                    case RepeatMode.one:
                      onSetRepeatMode(RepeatMode.off);
                      break;
                  }
                },
                tooltip: repeatMode == RepeatMode.off 
                    ? AppLocalizations.of(context)!.repeat_all_songs_label
                    : (repeatMode == RepeatMode.all 
                        ? AppLocalizations.of(context)!.repeat_one_song_label
                        : AppLocalizations.of(context)!.turn_repeat_off_label),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
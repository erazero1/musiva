import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musiva/core/utils/logger.dart';
import 'package:musiva/features/player/data/services/audio_handler.dart';
import 'package:musiva/features/player/data/services/audio_service_provider.dart';
import 'package:musiva/features/player/domain/entities/player_state.dart';
import 'package:musiva/features/songs/domain/entities/song.dart';
import 'package:musiva/features/songs/presentation/bloc/songs_bloc.dart';

part 'player_event.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final AudioServiceProvider _audioServiceProvider = AudioServiceProvider();
  MusivaAudioHandler? _audioHandler;
  StreamSubscription? _playbackStateSubscription;
  StreamSubscription? _customEventSubscription;
  Timer? _positionUpdateTimer;
  static const String _tag = 'PlayerBloc';
  
  // Context for localization
  BuildContext? _context;
  
  // Method to set context for localization
  void setContext(BuildContext context) {
    _context = context;
  }
  
  // Helper method to get localized strings
  String _getLocalizedString(String key, [Map<String, dynamic>? args]) {
    if (_context == null) {
      // Fallback to English hardcoded strings if context is not available
      switch (key) {
        case 'unknown_playback_error':
          return 'Unknown playback error';
        case 'no_more_songs_in_queue':
          return 'No more songs in queue';
        case 'end_of_queue_reached':
          return 'End of queue reached';
        case 'failed_to_initialize_audio_player':
          return 'Failed to initialize audio player: ${args?['error'] ?? ''}';
        case 'failed_to_initialize_player':
          return 'Failed to initialize player: ${args?['error'] ?? ''}';
        case 'failed_to_play_song':
          return 'Failed to play "${args?['title'] ?? ''}": ${args?['error'] ?? ''}';
        case 'no_song_to_play':
          return 'No song to play';
        case 'failed_to_pause_song':
          return 'Failed to pause song: ${args?['error'] ?? ''}';
        case 'failed_to_resume_song':
          return 'Failed to resume song: ${args?['error'] ?? ''}';
        default:
          return key;
      }
    }
    
    final localizations = AppLocalizations.of(_context!);
    if (localizations == null) {
      return key;
    }
    
    switch (key) {
      case 'unknown_playback_error':
        return localizations.unknown_playback_error;
      case 'no_more_songs_in_queue':
        return localizations.no_more_songs_in_queue;
      case 'end_of_queue_reached':
        return localizations.end_of_queue_reached;
      case 'failed_to_initialize_audio_player':
        return localizations.failed_to_initialize_audio_player(args?['error'] ?? '');
      case 'failed_to_initialize_player':
        return localizations.failed_to_initialize_player(args?['error'] ?? '');
      case 'failed_to_play_song':
        return localizations.failed_to_play_song(args?['title'] ?? '', args?['error'] ?? '');
      case 'no_song_to_play':
        return localizations.no_song_to_play;
      case 'failed_to_pause_song':
        return localizations.failed_to_pause_song(args?['error'] ?? '');
      case 'failed_to_resume_song':
        return localizations.failed_to_resume_song(args?['error'] ?? '');
      default:
        return key;
    }
  }

  PlayerBloc() : super(PlayerState()) {
    on<InitPlayer>(_onInitPlayer);
    on<PlaySong>(_onPlaySong);
    on<PlaySongAtIndex>(_onPlaySongAtIndex);
    on<PauseSong>(_onPauseSong);
    on<ResumeSong>(_onResumeSong);
    on<SeekTo>(_onSeekTo);
    on<NextSong>(_onNextSong);
    on<PreviousSong>(_onPreviousSong);
    on<ToggleShuffle>(_onToggleShuffle);
    on<SetRepeatMode>(_onSetRepeatMode);
    on<UpdatePosition>(_onUpdatePosition);
    on<SetQueue>(_onSetQueue);
    on<AddToQueue>(_onAddToQueue);
    on<RemoveFromQueue>(_onRemoveFromQueue);
    on<ClearQueue>(_onClearQueue);
    on<PlaybackError>(_onPlaybackError);
    on<StopPlayback>(_onStopPlayback);
    on<RefreshPlayerState>(_onRefreshPlayerState);
    on<SongPlayedEvent>(_onSongPlayed);
  }

  @override
  Future<void> close() async {
    _playbackStateSubscription?.cancel();
    _customEventSubscription?.cancel();
    _positionUpdateTimer?.cancel();
    
    // Properly dispose of the audio handler
    if (_audioHandler != null) {
      await _audioHandler!.stop();
      // We don't call dispose on the audio handler here because it's managed by the AudioServiceProvider
    }
    
    await super.close();
  }

  FutureOr<void> _onInitPlayer(InitPlayer event, Emitter<PlayerState> emit) async {
    try {
      log.i('$_tag: Initializing player');
      
      // Cancel existing timer and subscriptions if they exist
      _positionUpdateTimer?.cancel();
      _playbackStateSubscription?.cancel();
      _customEventSubscription?.cancel();
      
      // Initialize the audio handler
      try {
        _audioHandler = await _audioServiceProvider.getAudioHandler();
        
        // Immediately get the current state from the audio handler
        final currentState = _audioHandler!.getCurrentPlayerState();
        emit(currentState);
        
        // Subscribe to custom events from the audio handler
        // Instead of directly emitting from the listener, we'll add events to the bloc
        _customEventSubscription = _audioHandler!.customEvent.listen((event) {
          log.d('$_tag: Received custom event: $event');
          
          // Handle playback errors
          if (event['error'] == 'playback_error') {
            add(PlaybackError(event['message'] ?? _getLocalizedString('unknown_playback_error')));
          }
          
          // Handle song_played events
          if (event['type'] == 'song_played' && event['songId'] != null) {
            log.d('$_tag: Received song_played event for song ID: ${event['songId']}');
            add(SongPlayedEvent(event['songId']));
          }
          
          // Handle queue_end events
          if (event['type'] == 'queue_end') {
            log.d('$_tag: Received queue_end event: ${event['message']}');
            // Only add the error event if we don't already have the same error
            // This prevents multiple identical snackbars from appearing
            if (state.error != _getLocalizedString('no_more_songs_in_queue') && 
                state.error != _getLocalizedString('end_of_queue_reached')) {
              add(PlaybackError(event['message'] ?? _getLocalizedString('no_more_songs_in_queue')));
            }
          }
        });
      } catch (e, stackTrace) {
        log.e('$_tag: Error getting audio handler', e, stackTrace);
        emit(state.copyWith(
          playbackState: PlaybackState.error,
          error: _getLocalizedString('failed_to_initialize_audio_player', {'error': e.toString()}),
        ));
        return;
      }
      
      // Set up a timer to periodically update the position
      // Reduced update frequency to 1000ms (1 second) to optimize performance
      _positionUpdateTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
        if (_audioHandler != null) {
          try {
            // Add an event to update the position
            final currentPosition = _audioHandler!.getCurrentPosition();
            add(UpdatePosition(currentPosition));
          } catch (e) {
            log.w('$_tag: Error in timer callback: ${e.toString()}');
          }
        }
      });
      
      log.i('$_tag: Player initialized successfully');
    } catch (e, stackTrace) {
      log.e('$_tag: Error initializing player', e, stackTrace);
      emit(state.copyWith(
        playbackState: PlaybackState.error,
        error: 'Failed to initialize player: ${e.toString()}',
      ));
    }
  }

  FutureOr<void> _onPlaySong(PlaySong event, Emitter<PlayerState> emit) async {
    log.i('$_tag: Playing song: ${event.song.title}');
    
    emit(state.copyWith(playbackState: PlaybackState.loading));
    
    // Always increment play count, even if playback fails
    // This ensures analytics are accurate
    _incrementPlayCount(event.song.id);
    
    try {
      try {
        _audioHandler ??= await _audioServiceProvider.getAudioHandler();
      } catch (e, stackTrace) {
        log.e('$_tag: Error getting audio handler', e, stackTrace);
        emit(state.copyWith(
          playbackState: PlaybackState.error,
          error: 'Failed to initialize audio player: ${e.toString()}',
        ));
        return;
      }
      
      // Play the song using the audio handler
      await _audioHandler!.playSong(event.song, clearQueue: event.clearQueue);
      
      // Update the state with the new queue and current index from the audio handler
      final updatedState = _audioHandler!.getCurrentPlayerState();
      emit(state.copyWith(
        queue: updatedState.queue,
        currentIndex: updatedState.currentIndex,
        playbackState: updatedState.playbackState,
        duration: updatedState.duration,
      ));
      
      log.i('$_tag: Song playback started: ${event.song.title}');
    } catch (e, stackTrace) {
      log.e('$_tag: Error playing song: ${e.toString()}', e, stackTrace);
      
      // Even if playback fails, we still want to update the queue and current song
      // so the UI can show what song was attempted to be played
      emit(state.copyWith(
        playbackState: PlaybackState.error,
        error: 'Failed to play "${event.song.title}": ${e.toString()}',
        // If we have a queue, keep it; otherwise create a new one with just this song
        queue: state.queue.isEmpty ? [event.song] : state.queue,
        // If we're clearing the queue or it's empty, set index to 0
        currentIndex: event.clearQueue || state.queue.isEmpty ? 0 : state.currentIndex,
      ));
    }
  }
  
  // Helper method to increment play count
  void _incrementPlayCount(String songId) {
    try {
      // Create the SongsBloc event to increment play count
      final songPlayedEvent = SongPlayed(songId);
      
      // Log the attempt to increment play count
      log.d('$_tag: Incrementing play count for song ID: $songId');
      
      // Emit a custom event that the UI layer can listen for
      // This allows the UI to dispatch the SongPlayed event to the SongsBloc
      if (_audioHandler != null) {
        _audioHandler!.customEvent.add({
          'type': 'song_played',
          'songId': songId
        });
      }
      
      // Note: The actual dispatching of the SongPlayed event to SongsBloc
      // is handled by the UI layer that has access to both blocs
    } catch (e, stackTrace) {
      log.w('$_tag: Error incrementing play count: ${e.toString()}', e, stackTrace);
      // Silently fail - this is not critical functionality
    }
  }

  FutureOr<void> _onPlaySongAtIndex(PlaySongAtIndex event, Emitter<PlayerState> emit) async {
    if (event.index < 0 || event.index >= state.queue.length) {
      log.w('$_tag: Invalid index for playback: ${event.index}');
      return;
    }
    
    log.i('$_tag: Playing song at index: ${event.index}');
    
    emit(state.copyWith(
      playbackState: PlaybackState.loading,
    ));
    
    // Get the song at the specified index
    final song = state.queue[event.index];
    
    // Always increment play count, even if playback fails
    _incrementPlayCount(song.id);
    
    try {
      try {
        _audioHandler ??= await _audioServiceProvider.getAudioHandler();
      } catch (e, stackTrace) {
        log.e('$_tag: Error getting audio handler', e, stackTrace);
        emit(state.copyWith(
          playbackState: PlaybackState.error,
          error: 'Failed to initialize audio player: ${e.toString()}',
        ));
        return;
      }
      
      // Play the song at the specified index using the audio handler
      await _audioHandler!.playSongAtIndex(event.index);
      
      // Update the state with the new current index and playback state from the audio handler
      final updatedState = _audioHandler!.getCurrentPlayerState();
      emit(state.copyWith(
        currentIndex: updatedState.currentIndex,
        playbackState: updatedState.playbackState,
        duration: updatedState.duration,
      ));
      
      log.i('$_tag: Song playback started at index ${event.index}');
    } catch (e, stackTrace) {
      log.e('$_tag: Error playing song at index: ${e.toString()}', e, stackTrace);
      // Make sure the audio handler is initialized
      try {
        _audioHandler ??= await _audioServiceProvider.getAudioHandler();
      } catch (e, stackTrace) {
        log.e('$_tag: Error getting audio handler', e, stackTrace);
        emit(state.copyWith(
          playbackState: PlaybackState.error,
          error: 'Failed to initialize audio player: ${e.toString()}'
        ));
        return;
      }
      
      // Even if playback fails, we still want to update the current index
      // so the UI can show what song was attempted to be played
      emit(state.copyWith(
        playbackState: PlaybackState.error,
        error: 'Failed to play "${song.title}": ${e.toString()}',
        currentIndex: event.index
      ));
      
      // Get the updated state from the audio handler
      final updatedState = _audioHandler!.getCurrentPlayerState();
      log.i('$_tag: Moved to next song, current index: ${updatedState.currentIndex}');
    }
  }

  FutureOr<void> _onPauseSong(PauseSong event, Emitter<PlayerState> emit) async {
    try {
      log.i('$_tag: Pausing playback');
      
      // Always clear any error state when attempting to pause
      // This ensures the snackbar doesn't persist when user tries to pause
      bool hasError = state.error != null;
      
      if (state.playbackState == PlaybackState.playing || state.playbackState == PlaybackState.error) {
        _audioHandler ??= await _audioServiceProvider.getAudioHandler();
        
        await _audioHandler!.pause();
        
        // Update the state to reflect the paused state and clear any error
        emit(state.copyWith(
          playbackState: PlaybackState.paused,
          error: hasError ? null : state.error // Clear error if there was one
        ));
        
        log.i('$_tag: Playback paused');
      }
    } catch (e, stackTrace) {
      log.e('$_tag: Error pausing song', e, stackTrace);
      emit(state.copyWith(
        playbackState: PlaybackState.error,
        error: 'Failed to pause song: ${e.toString()}',
      ));
    }
  }

  FutureOr<void> _onResumeSong(ResumeSong event, Emitter<PlayerState> emit) async {
    try {
      log.i('$_tag: Resuming playback');
      
      // Check if we have a valid song to play
      if (state.queue.isEmpty || state.currentIndex < 0 || state.currentIndex >= state.queue.length) {
        log.w('$_tag: Cannot resume - no valid song in queue');
        emit(state.copyWith(
          error: 'No song to play',
          // Keep the paused state
          playbackState: PlaybackState.paused
        ));
        return;
      }
      
      // Always clear any error state when attempting to resume
      // This ensures the snackbar doesn't persist when user tries to play
      bool hasError = state.error != null;
      
      if (state.playbackState == PlaybackState.paused || state.playbackState == PlaybackState.error) {
        _audioHandler ??= await _audioServiceProvider.getAudioHandler();
        
        await _audioHandler!.play();
        
        // Update the state to reflect the playing state and clear any error
        emit(state.copyWith(
          playbackState: PlaybackState.playing,
          error: hasError ? null : state.error // Clear error if there was one
        ));
        
        log.i('$_tag: Playback resumed');
      }
    } catch (e, stackTrace) {
      log.e('$_tag: Error resuming song', e, stackTrace);
      emit(state.copyWith(
        playbackState: PlaybackState.error,
        error: 'Failed to resume song: ${e.toString()}',
      ));
    }
  }

  FutureOr<void> _onSeekTo(SeekTo event, Emitter<PlayerState> emit) async {
    try {
      log.i('$_tag: Seeking to position: ${event.position}');
      
      _audioHandler ??= await _audioServiceProvider.getAudioHandler();
      
      await _audioHandler!.seek(event.position);
      emit(state.copyWith(position: event.position));
      
      log.i('$_tag: Seek completed');
    } catch (e, stackTrace) {
      log.e('$_tag: Error seeking', e, stackTrace);
      emit(state.copyWith(
        error: 'Failed to seek: ${e.toString()}',
      ));
    }
  }

  FutureOr<void> _onNextSong(NextSong event, Emitter<PlayerState> emit) async {
    try {
      log.i('$_tag: Moving to next song');
      
      if (state.queue.isEmpty) {
        log.w('$_tag: Queue is empty, cannot play next song');
        // Show a snackbar message and set playback state to paused
        emit(state.copyWith(
          error: 'No more songs in queue',
          playbackState: PlaybackState.paused
        ));
        return;
      }
      
      // Check if we're at the end of the queue and repeat is off
      if (state.currentIndex >= state.queue.length - 1 && state.repeatMode == RepeatMode.off) {
        log.i('$_tag: End of queue reached with repeat off, looping back to start');
        
        // Instead of showing an error, we'll loop back to the beginning of the queue
        try {
          if (_audioHandler != null) {
            // Play the first song in the queue
            await _audioHandler!.skipToQueueItem(0);
            
            // Get the updated state from the audio handler
            final updatedState = _audioHandler!.getCurrentPlayerState();
            
            // Update our state with the audio handler's state
            emit(updatedState);
            
            log.i('$_tag: Looped back to first song in queue');
          }
        } catch (e, stackTrace) {
          log.e('$_tag: Error looping back to start of queue', e, stackTrace);
          emit(state.copyWith(
            playbackState: PlaybackState.error,
            error: 'Failed to loop back to start of queue: ${e.toString()}',
          ));
        }
        
        return;
      }
      
      // Make sure the audio handler is initialized
      try {
        _audioHandler ??= await _audioServiceProvider.getAudioHandler();
      } catch (e, stackTrace) {
        log.e('$_tag: Error getting audio handler', e, stackTrace);
        emit(state.copyWith(
          playbackState: PlaybackState.error,
          error: 'Failed to initialize audio player: ${e.toString()}',
        ));
        return;
      }
      
      // Use the audio handler to skip to the next song
      // This will handle moving the current song to history
      await _audioHandler!.skipToNext();
      
      // Get the updated state from the audio handler
      final updatedState = _audioHandler!.getCurrentPlayerState();
      
      // Update our state with the audio handler's state
      emit(updatedState);
      
      log.i('$_tag: Moved to next song, current index: ${updatedState.currentIndex}');
    } catch (e, stackTrace) {
      log.e('$_tag: Error playing next song', e, stackTrace);
      emit(state.copyWith(
        playbackState: PlaybackState.error,
        error: 'Failed to play next song: ${e.toString()}',
      ));
    }
  }

  FutureOr<void> _onPreviousSong(PreviousSong event, Emitter<PlayerState> emit) async {
    try {
      log.i('$_tag: Moving to previous song');
      
      // Make sure the audio handler is initialized
      try {
        _audioHandler ??= await _audioServiceProvider.getAudioHandler();
      } catch (e, stackTrace) {
        log.e('$_tag: Error getting audio handler', e, stackTrace);
        emit(state.copyWith(
          playbackState: PlaybackState.error,
          error: 'Failed to initialize audio player: ${e.toString()}',
        ));
        return;
      }
      
      // Use the audio handler to skip to the previous song
      // This will handle restoring songs from history
      await _audioHandler!.skipToPrevious();
      
      // Get the updated state from the audio handler
      final updatedState = _audioHandler!.getCurrentPlayerState();
      
      // Update our state with the audio handler's state
      emit(updatedState);
      
      log.i('$_tag: Moved to previous song, current index: ${updatedState.currentIndex}');
    } catch (e, stackTrace) {
      log.e('$_tag: Error playing previous song', e, stackTrace);
      emit(state.copyWith(
        playbackState: PlaybackState.error,
        error: 'Failed to play previous song: ${e.toString()}',
      ));
    }
  }

  FutureOr<void> _onToggleShuffle(ToggleShuffle event, Emitter<PlayerState> emit) async {
    try {
      log.i('$_tag: Toggling shuffle mode');
      
      if (state.queue.isEmpty) {
        log.w('$_tag: Queue is empty, cannot shuffle');
        return null;
      }
      
      if (state.isShuffled) {
        // Unshuffle - restore original order
        // In a real app, you'd keep track of the original order
        log.i('$_tag: Unshuffling queue');
        emit(state.copyWith(isShuffled: false));
      } else {
        // Shuffle the queue but keep the current song as the first item
        log.i('$_tag: Shuffling queue');
        
        if (state.currentIndex < 0) {
          return null;
        }
        
        final currentSong = state.queue[state.currentIndex];
        final remainingSongs = List<Song>.from(state.queue)..removeAt(state.currentIndex);
        
        // Shuffle the remaining songs
        remainingSongs.shuffle(Random());
        
        // Put the current song back at the beginning
        final shuffledQueue = [currentSong, ...remainingSongs];
        
        emit(state.copyWith(
          queue: shuffledQueue,
          currentIndex: 0,
          isShuffled: true,
        ));
      }
    } catch (e, stackTrace) {
      log.e('$_tag: Error toggling shuffle', e, stackTrace);
      emit(state.copyWith(
        error: 'Failed to toggle shuffle: ${e.toString()}',
      ));
    }
  }

  FutureOr<void> _onSetRepeatMode(SetRepeatMode event, Emitter<PlayerState> emit) async {
    try {
      log.i('$_tag: Setting repeat mode to: ${event.mode}');
      
      _audioHandler ??= await _audioServiceProvider.getAudioHandler();
      
      // Use the new setAppRepeatMode method
      await _audioHandler!.setAppRepeatMode(event.mode);
      
      emit(state.copyWith(repeatMode: event.mode));
    } catch (e, stackTrace) {
      log.e('$_tag: Error setting repeat mode', e, stackTrace);
    }
  }
  
  // _onRemoveFromQueue is implemented below

  FutureOr<void> _onUpdatePosition(UpdatePosition event, Emitter<PlayerState> emit) {
    emit(state.copyWith(position: event.position));
  }
  
  FutureOr<void> _onRefreshPlayerState(RefreshPlayerState event, Emitter<PlayerState> emit) async {
    try {
      // Clear any error state when refreshing
      bool hasError = state.error != null;
      
      if (_audioHandler != null) {
        // Get the current state from the audio handler
        final currentState = _audioHandler!.getCurrentPlayerState();
        
        // Check if the queue in the audio handler is different from our state
        // This ensures that any changes to the queue in the audio handler are reflected in our state
        if (currentState.queue.length != state.queue.length) {
          log.d('$_tag: Queue length mismatch detected. PlayerBloc: ${state.queue.length}, AudioHandler: ${currentState.queue.length}');
          // Use the audio handler's queue as the source of truth, but preserve our error clearing
          emit(hasError ? currentState.copyWith(error: null) : currentState);
          return; // Return early to avoid multiple emits
        }
        
        // Check if the current index in the audio handler is different from our state
        if (currentState.currentIndex != state.currentIndex) {
          log.d('$_tag: Current index mismatch detected. PlayerBloc: ${state.currentIndex}, AudioHandler: ${currentState.currentIndex}');
          // Use the audio handler's current index as the source of truth
          emit(state.copyWith(
            currentIndex: currentState.currentIndex,
            playbackState: currentState.playbackState,
            position: currentState.position,
            duration: currentState.duration,
            error: hasError ? null : state.error // Clear error if there was one
          ));
          return; // Return early to avoid multiple emits
        }
        
        // If no major discrepancies, just update the position and playback state
        emit(state.copyWith(
          position: currentState.position,
          playbackState: currentState.playbackState,
          duration: currentState.duration,
          error: hasError ? null : state.error // Clear error if there was one
        ));
      } else if (hasError) {
        // If we don't have an audio handler but we have an error, just clear the error
        emit(state.copyWith(error: null));
      }
    } catch (e, stackTrace) {
      log.e('$_tag: Error refreshing player state', e, stackTrace);
    }
  }

  FutureOr<void> _onSetQueue(SetQueue event, Emitter<PlayerState> emit) {
    try {
      log.i('$_tag: Setting queue with ${event.songs.length} songs');
      
      emit(state.copyWith(
        queue: event.songs,
        currentIndex: event.songs.isEmpty ? -1 : 0,
      ));
      
      if (event.autoplay && event.songs.isNotEmpty) {
        add(PlaySongAtIndex(0));
      }
    } catch (e, stackTrace) {
      log.e('$_tag: Error setting queue', e, stackTrace);
      emit(state.copyWith(
        error: 'Failed to set queue: ${e.toString()}',
      ));
    }
  }

  FutureOr<void> _onAddToQueue(AddToQueue event, Emitter<PlayerState> emit) async {
    try {
      log.i('$_tag: Adding song to queue: ${event.song.title}');
      
      final newQueue = List<Song>.from(state.queue);
      newQueue.add(event.song);
      
      // Make sure the audio handler is initialized and synchronized
      try {
        _audioHandler ??= await _audioServiceProvider.getAudioHandler();
        // Add the song to the audio handler's queue as well
        await _audioHandler!.addToQueue(event.song, playIfEmpty: event.playIfEmpty);
      } catch (e, stackTrace) {
        log.e('$_tag: Error getting audio handler', e, stackTrace);
        emit(state.copyWith(
          error: 'Failed to initialize audio player: ${e.toString()}',
        ));
        return;
      }
      
      emit(state.copyWith(queue: newQueue));
      log.i('$_tag: Song added to queue: ${event.song.title}');
      log.d('$_tag: Current queue: ${newQueue.map((s) => s.title).join(', ')}');

      // If this is the first song, start playing it
      if (state.queue.isEmpty && event.playIfEmpty) {
        add(PlaySongAtIndex(0));
      }
    } catch (e, stackTrace) {
      log.e('$_tag: Error adding to queue', e, stackTrace);
      emit(state.copyWith(
        error: 'Failed to add to queue: ${e.toString()}',
      ));
    }
  }

  FutureOr<void> _onRemoveFromQueue(RemoveFromQueue event, Emitter<PlayerState> emit) async {
    try {
      log.i('$_tag: Removing song from queue at index: ${event.index}');
      
      if (event.index < 0 || event.index >= state.queue.length) {
        log.w('$_tag: Invalid index for removal: ${event.index}');
        return;
      }
      
      // Make sure the audio handler is initialized
      try {
        _audioHandler ??= await _audioServiceProvider.getAudioHandler();
      } catch (e, stackTrace) {
        log.e('$_tag: Error getting audio handler', e, stackTrace);
        emit(state.copyWith(
          error: 'Failed to initialize audio player: ${e.toString()}',
        ));
        return;
      }
      
      // Remove the song from the queue using the audio handler
      await _audioHandler!.removeFromQueue(event.index);
      
      // Create a new queue by removing the song at the specified index
      final newQueue = List<Song>.from(state.queue);
      newQueue.removeAt(event.index);
      
      int newIndex = state.currentIndex;
      
      // Adjust current index if needed
      if (event.index == state.currentIndex) {
        // We're removing the current song
        if (newQueue.isEmpty) {
          // Queue is now empty
          newIndex = -1;
          add(StopPlayback());
        } else if (event.index >= newQueue.length) {
          // We removed the last song, go to the new last song
          newIndex = newQueue.length - 1;
          add(PlaySongAtIndex(newIndex));
        } else {
          // Play the song that's now at this position
          add(PlaySongAtIndex(newIndex));
        }
      } else if (event.index < state.currentIndex) {
        // We removed a song before the current one, adjust index
        newIndex--;
      }
      
      emit(state.copyWith(
        queue: newQueue,
        currentIndex: newIndex,
      ));
    } catch (e, stackTrace) {
      log.e('$_tag: Error removing from queue', e, stackTrace);
      emit(state.copyWith(
        error: 'Failed to remove from queue: ${e.toString()}',
      ));
    }
  }

  FutureOr<void> _onClearQueue(ClearQueue event, Emitter<PlayerState> emit) async {
    try {
      log.i('$_tag: Clearing queue');
      
      _audioHandler ??= await _audioServiceProvider.getAudioHandler();
      await _audioHandler!.stop();
      
      emit(state.copyWith(
        queue: [],
        currentIndex: -1,
        playbackState: PlaybackState.stopped,
      ));
    } catch (e, stackTrace) {
      log.e('$_tag: Error clearing queue', e, stackTrace);
      emit(state.copyWith(
        error: 'Failed to clear queue: ${e.toString()}',
      ));
    }
  }

  FutureOr<void> _onPlaybackError(PlaybackError event, Emitter<PlayerState> emit) {
    log.e('$_tag: Playback error: ${event.error}');
    
    // Only update the error if it's different from the current error
    // This prevents duplicate error messages from appearing
    if (state.error != event.error) {
      emit(state.copyWith(
        playbackState: PlaybackState.error,
        error: event.error,
      ));
    }
  }

  FutureOr<void> _onStopPlayback(StopPlayback event, Emitter<PlayerState> emit) async {
    try {
      log.i('$_tag: Stopping playback');
      
      _audioHandler ??= await _audioServiceProvider.getAudioHandler();
      await _audioHandler!.stop();
      
      emit(state.copyWith(
        playbackState: PlaybackState.stopped,
        position: Duration.zero,
      ));
    } catch (e, stackTrace) {
      log.e('$_tag: Error stopping playback', e, stackTrace);
      emit(state.copyWith(
        error: 'Failed to stop playback: ${e.toString()}',
      ));
    }
  }
  
  FutureOr<void> _onSongPlayed(SongPlayedEvent event, Emitter<PlayerState> emit) {
    // This event is meant to be observed by the UI layer
    // The UI layer should then dispatch the SongPlayed event to the SongsBloc
    log.i('$_tag: Song played event for song ID: ${event.songId}');
    
    // No state changes needed for this event
    // It's just a notification that a song was played
  }
}
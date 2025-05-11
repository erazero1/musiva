import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musiva/core/utils/logger.dart';
import 'package:musiva/features/player/domain/entities/player_state.dart' as app_player_state;
import 'package:musiva/features/songs/domain/entities/song.dart';

class MusivaAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final _tag = 'MusivaAudioHandler';
  
  // The BaseAudioHandler already has a customEvent property of type PublishSubject<dynamic>
  // We can use this directly for our custom events
  
  // Keep track of the current queue, history, and index
  List<Song> _queue = [];         // Current and upcoming songs
  List<Song> _history = [];       // Previously played songs
  int _currentIndex = -1;
  app_player_state.RepeatMode _repeatMode = app_player_state.RepeatMode.off;
  bool _isShuffled = false;

  MusivaAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    try {
      // Configure audio player with better buffering and error handling
      // Note: In just_audio 0.9.46, we can't directly set audio attributes and load configuration
      // We'll use the available methods instead
      
      // Set up initial audio source with no preload to configure the player
      // This will be replaced when an actual song is played
      try {
        await _player.setVolume(1.0);
        await _player.setSpeed(1.0);
      } catch (e) {
        log.w('$_tag: Error setting up player: ${e.toString()}');
      }
      
      // Link the player's state to the audio handler's state
      _player.playbackEventStream.listen(_broadcastState);
      
      // Special processing for state completion
      _player.processingStateStream.listen((state) async {
        if (state == ProcessingState.completed) {
          await _handlePlaybackCompletion();
        }
      });
      
      // Handle errors with more detailed logging
      _player.playbackEventStream.listen(
        (event) {},
        onError: (Object e, StackTrace st) {
          String errorDetails = 'Unknown error';
          
          // Extract more specific error information
          if (e.toString().contains('Format')) {
            errorDetails = 'Unsupported audio format';
          } else if (e.toString().contains('Connection')) {
            errorDetails = 'Network connection issue';
          } else if (e.toString().contains('Permission')) {
            errorDetails = 'Permission denied';
          } else {
            errorDetails = e.toString();
          }
          
          log.e('$_tag: Audio player error: $errorDetails', e, st);
          
          // Update playback state
          playbackState.add(playbackState.value.copyWith(
            processingState: AudioProcessingState.error,
            playing: false,
          ));
          
          // Send custom event with error details
          customEvent.add({
            'error': 'playback_error',
            'message': 'Playback error: $errorDetails',
          });
        },
      );
      
      // Listen for player errors and handle idle state
      _player.playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.idle) {
          log.d('$_tag: Player returned to idle state, may need to reinitialize');
          
          // Update playback state to reflect the idle state
          playbackState.add(playbackState.value.copyWith(
            processingState: AudioProcessingState.idle,
            playing: false,
          ));
          
          // Only attempt to reinitialize if we have a valid current song
          if (_currentIndex >= 0 && _currentIndex < _queue.length) {
            // We could potentially reinitialize the player here if needed
            // But for now, just ensure the state is correctly reflected
          }
        }
      });
      
      log.i('$_tag: Audio handler initialized with enhanced configuration');
    } catch (e, stackTrace) {
      log.e('$_tag: Error initializing audio handler: ${e.toString()}', e, stackTrace);
    }
  }

  // Convert our Song model to MediaItem for audio_service
  MediaItem _songToMediaItem(Song song) {
    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      artUri: Uri.parse(song.artworkUrl),
      duration: song.duration,
      extras: {
        'audioUrl': song.audioUrl,
      },
    );
  }

  // Convert a list of Songs to MediaItems
  List<MediaItem> _songsToMediaItems(List<Song> songs) {
    return songs.map(_songToMediaItem).toList();
  }

  // Handle playback completion based on repeat mode
  Future<void> _handlePlaybackCompletion() async {
    switch (_repeatMode) {
      case app_player_state.RepeatMode.one:
        // Repeat the current song
        await _player.seek(Duration.zero);
        await _player.play();
        break;
      case app_player_state.RepeatMode.all:
        // If we're at the end of the queue, go back to the beginning
        if (_currentIndex >= _queue.length - 1) {
          // Set the last song as the only item in history
          if (_currentIndex >= 0 && _currentIndex < _queue.length) {
            _history = [_queue[_currentIndex]];
            
            // If there are more songs in the queue, keep only the first one
            if (_queue.length > 1) {
              final firstSong = _queue[0];
              _queue = [firstSong];
            } else {
              _queue.removeAt(_currentIndex);
            }
          }
          
          // Play the first song
          skipToQueueItem(0);
        } else {
          // Normal next song
          skipToNext();
        }
        break;
      case app_player_state.RepeatMode.off:
        // If we're at the end of the queue, loop back to the beginning
        if (_currentIndex >= _queue.length - 1) {
          log.i('$_tag: End of queue reached during playback completion, looping back to start');
          
          // Set the last song as the only item in history
          if (_currentIndex >= 0 && _currentIndex < _queue.length) {
            _history = [_queue[_currentIndex]];
          }
          
          // If there are songs in the queue, play the first one
          if (_queue.isNotEmpty) {
            // Play the first song
            await skipToQueueItem(0);
          } else {
            // If queue is somehow empty, just pause
            await _player.pause();
          }
        } else {
          // Normal next song
          skipToNext();
        }
        break;
    }
  }

  // Broadcast the current state to audio_service
  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    final processingState = const {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[_player.processingState]!;
    
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: processingState,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
    ));
  }

  // Load and play a specific song
  Future<void> playSong(Song song, {bool clearQueue = false}) async {
    try {
      log.i('$_tag: Playing song: ${song.title}');
      
      if (clearQueue) {
        // If we're clearing the queue, also clear the history
        _history = [];
        _queue = [song];
        _currentIndex = 0;
      } else if (!_queue.contains(song)) {
        // If the song is not in the queue, add it
        _queue.add(song);
        _currentIndex = _queue.length - 1;
      } else {
        // If the song is already in the queue, just play it
        // If the current song is being played again, don't move it to history
        if (_currentIndex >= 0 && _currentIndex < _queue.length && _queue[_currentIndex].id != song.id) {
          // Set the current song as the only item in history
          _history = [_queue[_currentIndex]];
        }
        _currentIndex = _queue.indexOf(song);
      }
      
      // Update the queue in audio_service
      final mediaItems = _songsToMediaItems(_queue);
      queue.add(mediaItems);
      if (_currentIndex >= 0 && _currentIndex < mediaItems.length) {
        mediaItem.add(mediaItems[_currentIndex]);
      }
      
      // Start playback with retry mechanism
      await _player.stop();
      
      // Log the audio URL for debugging
      log.d('$_tag: Attempting to play audio from URL: ${song.audioUrl}');
      
      // Try to set the audio source with retry
      bool success = false;
      int retryCount = 0;
      Exception? lastError;
      
      while (!success && retryCount < 3) {
        try {
          // Set audio source with specific configuration
          await _player.setAudioSource(
            AudioSource.uri(
              Uri.parse(song.audioUrl),
              // Add tag with additional metadata
              tag: {
                'title': song.title,
                'artist': song.artist,
                'id': song.id,
              },
            ),
            // Preload the audio to detect issues early
            preload: true,
            // Initialize position to beginning
            initialPosition: Duration.zero,
          );
          success = true;
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
          log.w('$_tag: Error setting audio source (attempt ${retryCount + 1}/3): ${e.toString()}');
          retryCount++;
          
          if (retryCount < 3) {
            // Wait before retrying
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
          }
        }
      }
      
      if (!success) {
        throw lastError ?? Exception('Failed to set audio source after multiple attempts');
      }
      
      // Start playback
      await _player.play();
      
      log.i('$_tag: Song playback started: ${song.title}');
    } catch (e, stackTrace) {
      log.e('$_tag: Error playing song: ${e.toString()}', e, stackTrace);
      
      // Update playback state to error
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        playing: false,
      ));
      
      // Send custom event with error details
      customEvent.add({
        'error': 'playback_error',
        'message': 'Failed to play "${song.title}": ${e.toString()}',
        'songId': song.id
      });
    }
  }

  // Play a song at a specific index in the queue
  Future<void> playSongAtIndex(int index) async {
    try {
      if (index < 0 || index >= _queue.length) {
        log.w('$_tag: Invalid index for playback: $index');
        return;
      }
      
      log.i('$_tag: Playing song at index: $index');
      
      // If we're changing to a different song, set the current song as the only item in history
      if (_currentIndex >= 0 && _currentIndex < _queue.length && _currentIndex != index) {
        // Limit history to only 1 song
        _history = [_queue[_currentIndex]];
      }
      
      _currentIndex = index;
      final song = _queue[index];
      
      // Update the current media item
      mediaItem.add(_songToMediaItem(song));
      
      // Start playback with retry mechanism
      await _player.stop();
      
      // Log the audio URL for debugging
      log.d('$_tag: Attempting to play audio from URL: ${song.audioUrl}');
      
      // Try to set the audio source with retry
      bool success = false;
      int retryCount = 0;
      Exception? lastError;
      
      while (!success && retryCount < 3) {
        try {
          // Set audio source with specific configuration
          await _player.setAudioSource(
            AudioSource.uri(
              Uri.parse(song.audioUrl),
              // Add tag with additional metadata
              tag: {
                'title': song.title,
                'artist': song.artist,
                'id': song.id,
              },
            ),
            // Preload the audio to detect issues early
            preload: true,
            // Initialize position to beginning
            initialPosition: Duration.zero,
          );
          success = true;
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
          log.w('$_tag: Error setting audio source (attempt ${retryCount + 1}/3): ${e.toString()}');
          retryCount++;
          
          if (retryCount < 3) {
            // Wait before retrying
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
          }
        }
      }
      
      if (!success) {
        throw lastError ?? Exception('Failed to set audio source after multiple attempts');
      }
      
      // Start playback
      await _player.play();
      
      log.i('$_tag: Song playback started at index $index: ${song.title}');
    } catch (e, stackTrace) {
      log.e('$_tag: Error playing song at index: ${e.toString()}', e, stackTrace);
      
      // Update playback state to error
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        playing: false,
      ));
      
      // Send custom event with error details
      customEvent.add({
        'error': 'playback_error',
        'message': 'Failed to play song at index $index: ${e.toString()}',
        'songId': _queue[index].id
      });
    }
  }

  // Set the queue of songs
  Future<void> setQueue(List<Song> songs, {bool autoplay = false}) async {
    try {
      log.i('$_tag: Setting queue with ${songs.length} songs');
      
      // Clear history when setting a new queue
      _history = [];
      _queue = songs;
      _currentIndex = songs.isEmpty ? -1 : 0;
      
      // Update the queue in audio_service
      final mediaItems = _songsToMediaItems(songs);
      queue.add(mediaItems);
      
      if (autoplay && songs.isNotEmpty) {
        await playSongAtIndex(0);
      }
    } catch (e, stackTrace) {
      log.e('$_tag: Error setting queue', e, stackTrace);
    }
  }

  // Add a song to the queue
  Future<void> addToQueue(Song song, {bool playIfEmpty = false}) async {
    try {
      log.i('$_tag: Adding song to queue: ${song.title}');
      
      // Always add the song to the queue, even if it's a duplicate
      // This allows users to add the same song multiple times
      _queue.add(song);
      
      // Update the queue in audio_service
      final mediaItems = _songsToMediaItems(_queue);
      queue.add(mediaItems);
      
      log.d('$_tag: Queue updated, now contains ${_queue.length} songs');
      log.d('$_tag: Current queue: ${_queue.map((s) => s.title).join(', ')}');
      
      // If this is the first song, start playing it
      if (_queue.length == 1 && playIfEmpty) {
        await playSongAtIndex(0);
      }
    } catch (e, stackTrace) {
      log.e('$_tag: Error adding to queue', e, stackTrace);
    }
  }

  // Remove a song from the queue
  Future<void> removeFromQueue(int index) async {
    try {
      log.i('$_tag: Removing song from queue at index: $index');
      
      if (index < 0 || index >= _queue.length) {
        log.w('$_tag: Invalid index for removal: $index');
        return;
      }
      
      _queue.removeAt(index);
      
      // Update the queue in audio_service
      final mediaItems = _songsToMediaItems(_queue);
      queue.add(mediaItems);
      
      // Adjust current index if needed
      if (index == _currentIndex) {
        // We're removing the current song
        if (_queue.isEmpty) {
          // Queue is now empty
          _currentIndex = -1;
          await stop();
        } else if (index >= _queue.length) {
          // We removed the last song, go to the new last song
          _currentIndex = _queue.length - 1;
          await playSongAtIndex(_currentIndex);
        } else {
          // Play the song that's now at this position
          await playSongAtIndex(_currentIndex);
        }
      } else if (index < _currentIndex) {
        // We removed a song before the current one, adjust index
        _currentIndex--;
      }
    } catch (e, stackTrace) {
      log.e('$_tag: Error removing from queue', e, stackTrace);
    }
  }

  // Toggle shuffle mode
  Future<void> toggleShuffle() async {
    try {
      log.i('$_tag: Toggling shuffle mode');
      
      if (_queue.isEmpty) {
        log.w('$_tag: Queue is empty, cannot shuffle');
        return;
      }
      
      _isShuffled = !_isShuffled;
      
      // Implement shuffle logic here
      // This is a simplified version - in a real app, you'd want to keep track of the original order
      if (_isShuffled) {
        // Shuffle the queue but keep the current song as the first item
        if (_currentIndex < 0) {
          return;
        }
        
        final currentSong = _queue[_currentIndex];
        final remainingSongs = List<Song>.from(_queue)..removeAt(_currentIndex);
        
        // Shuffle the remaining songs
        remainingSongs.shuffle();
        
        // Put the current song back at the beginning
        _queue = [currentSong, ...remainingSongs];
        _currentIndex = 0;
        
        // Update the queue in audio_service
        final mediaItems = _songsToMediaItems(_queue);
        queue.add(mediaItems);
      }
      
      customEvent.add({'shuffleEnabled': _isShuffled});
    } catch (e, stackTrace) {
      log.e('$_tag: Error toggling shuffle', e, stackTrace);
    }
  }

  // Custom method to set our app's repeat mode
  Future<void> setAppRepeatMode(app_player_state.RepeatMode mode) async {
    log.i('$_tag: Setting repeat mode to: $mode');
    _repeatMode = mode;
    
    // Map our app's repeat mode to audio_service's repeat mode
    final audioServiceRepeatMode = {
      app_player_state.RepeatMode.off: AudioServiceRepeatMode.none,
      app_player_state.RepeatMode.all: AudioServiceRepeatMode.all,
      app_player_state.RepeatMode.one: AudioServiceRepeatMode.one,
    }[mode]!;
    
    // Broadcast the repeat mode change
    playbackState.add(playbackState.value.copyWith(
      repeatMode: audioServiceRepeatMode,
    ));
    
    customEvent.add({'repeatMode': mode.index});
  }
  
  // Override the BaseAudioHandler method
  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    log.i('$_tag: Setting audio service repeat mode to: $repeatMode');
    
    // Map audio_service's repeat mode to our app's repeat mode
    final appRepeatMode = {
      AudioServiceRepeatMode.none: app_player_state.RepeatMode.off,
      AudioServiceRepeatMode.all: app_player_state.RepeatMode.all,
      AudioServiceRepeatMode.one: app_player_state.RepeatMode.one,
      AudioServiceRepeatMode.group: app_player_state.RepeatMode.all, // Map group to all as a fallback
    }[repeatMode]!;
    
    // Use our custom method to set the repeat mode
    await setAppRepeatMode(appRepeatMode);
  }

  // Get the current app player state
  app_player_state.PlayerState getCurrentPlayerState() {
    final currentSong = _currentIndex >= 0 && _currentIndex < _queue.length ? _queue[_currentIndex] : null;
    
    final appPlaybackState = {
      AudioProcessingState.idle: app_player_state.PlaybackState.idle,
      AudioProcessingState.loading: app_player_state.PlaybackState.loading,
      AudioProcessingState.buffering: app_player_state.PlaybackState.loading,
      AudioProcessingState.ready: _player.playing ? app_player_state.PlaybackState.playing : app_player_state.PlaybackState.paused,
      AudioProcessingState.completed: app_player_state.PlaybackState.stopped,
      AudioProcessingState.error: app_player_state.PlaybackState.error,
    }[playbackState.value.processingState]!;
    
    return app_player_state.PlayerState(
      playbackState: appPlaybackState,
      queue: _queue,
      history: _history,
      currentIndex: _currentIndex,
      position: _player.position,
      duration: currentSong?.duration ?? Duration.zero,
      isShuffled: _isShuffled,
      repeatMode: _repeatMode,
      error: playbackState.value.processingState == AudioProcessingState.error ? 'Playback error' : null,
    );
  }
  
  // Get the current position
  Duration getCurrentPosition() {
    return _player.position;
  }

  // Override methods from BaseAudioHandler

  @override
  Future<void> play() async {
    try {
      log.i('$_tag: Play command received');
      await _player.play();
    } catch (e, stackTrace) {
      log.e('$_tag: Error playing', e, stackTrace);
    }
  }

  @override
  Future<void> pause() async {
    try {
      log.i('$_tag: Pause command received');
      await _player.pause();
    } catch (e, stackTrace) {
      log.e('$_tag: Error pausing', e, stackTrace);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      log.i('$_tag: Seek command received: $position');
      await _player.seek(position);
    } catch (e, stackTrace) {
      log.e('$_tag: Error seeking', e, stackTrace);
    }
  }

  @override
  Future<void> stop() async {
    try {
      log.i('$_tag: Stop command received');
      
      // First update the state to ensure UI is updated immediately
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ));
      
      // Then stop the player
      await _player.stop();
      
      // Ensure the state is still correct after stopping
      // This helps prevent any race conditions
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ));
    } catch (e, stackTrace) {
      log.e('$_tag: Error stopping', e, stackTrace);
      
      // Even if there's an error, try to ensure the state is correct
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ));
    }
  }

  @override
  Future<void> skipToNext() async {
    try {
      log.i('$_tag: Skip to next command received');
      
      // Note: The PlayerBloc now handles the empty queue case before calling this method
      if (_queue.isEmpty) {
        log.w('$_tag: Queue is empty, cannot skip to next');
        return;
      }
      
      // If we're repeating the current song, just restart it
      if (_repeatMode == app_player_state.RepeatMode.one) {
        await _player.seek(Duration.zero);
        await _player.play();
        return;
      }
      
      // If we're at the end of the queue
      if (_currentIndex >= _queue.length - 1) {
        // If repeat all is enabled, loop back to the beginning
        if (_repeatMode == app_player_state.RepeatMode.all) {
          // Move all songs except the first one to history
          if (_queue.length > 1) {
            // Set current song as the only item in history
            if (_currentIndex >= 0 && _currentIndex < _queue.length) {
              _history = [_queue[_currentIndex]];
            }
            
            // Play the first song
            final firstSong = _queue[0];
            _queue = [firstSong];
            _currentIndex = 0;
            
            await playSongAtIndex(0);
          } else {
            // Only one song in queue, just restart it
            await _player.seek(Duration.zero);
            await _player.play();
          }
        } else {
          // We're at the end and repeat is off
          // Instead of stopping, we'll loop back to the beginning
          log.i('$_tag: End of queue reached with no repeat, looping back to start');
          
          // Set current song as the only item in history
          if (_currentIndex >= 0 && _currentIndex < _queue.length) {
            _history = [_queue[_currentIndex]];
          }
          
          // Play the first song
          await skipToQueueItem(0);
          return;
        }
        return;
      }
      
      // Normal case: move to next song
      if (_currentIndex >= 0 && _currentIndex < _queue.length) {
        // Set current song as the only item in history
        _history = [_queue[_currentIndex]];
        
        // Remove the current song from the queue
        _queue.removeAt(_currentIndex);
        
        // Current index stays the same since we removed the current song
        // and the next song is now at the same index
        
        // Update the queue in audio_service
        final mediaItems = _songsToMediaItems(_queue);
        queue.add(mediaItems);
        
        // Play the song at the current index (which is now the next song)
        await playSongAtIndex(_currentIndex);
      }
    } catch (e, stackTrace) {
      log.e('$_tag: Error skipping to next', e, stackTrace);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      log.i('$_tag: Skip to previous command received');
      
      // If we're more than 3 seconds into the song, restart it instead of going to previous
      if (_player.position.inSeconds > 3) {
        log.i('$_tag: Restarting current song');
        await _player.seek(Duration.zero);
        return;
      }
      
      // If we're repeating the current song, just restart it
      if (_repeatMode == app_player_state.RepeatMode.one) {
        await _player.seek(Duration.zero);
        await _player.play();
        return;
      }
      
      // Check if we have a song in history to go back to
      if (_history.isNotEmpty) {
        // Get the previous song from history (there should be only one)
        final previousSong = _history[0];
        
        // Clear the history since we're using the previous song now
        _history = [];
        
        // Add it back to the beginning of the queue
        _queue.insert(0, previousSong);
        
        // If we were already playing a song, increment the current index
        if (_currentIndex >= 0) {
          _currentIndex++;
        } else {
          _currentIndex = 0;
        }
        
        // Update the queue in audio_service
        final mediaItems = _songsToMediaItems(_queue);
        queue.add(mediaItems);
        
        // Play the previous song (now at index 0)
        await playSongAtIndex(0);
        return;
      }
      
      // If no history but we're not at the beginning of the queue
      if (_currentIndex > 0) {
        // Normal previous song
        final prevIndex = _currentIndex - 1;
        await playSongAtIndex(prevIndex);
        return;
      }
      
      // We're at the beginning of the queue with no history
      if (_repeatMode == app_player_state.RepeatMode.all && _queue.isNotEmpty) {
        // Loop to the end with repeat all
        await playSongAtIndex(_queue.length - 1);
      } else {
        // Just restart the current song
        await _player.seek(Duration.zero);
      }
    } catch (e, stackTrace) {
      log.e('$_tag: Error skipping to previous', e, stackTrace);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    try {
      log.i('$_tag: Skip to queue item command received: $index');
      await playSongAtIndex(index);
    } catch (e, stackTrace) {
      log.e('$_tag: Error skipping to queue item', e, stackTrace);
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    log.i('$_tag: Task removed');
    await stop();
    await super.onTaskRemoved();
  }

  @override
  Future<void> onNotificationDeleted() async {
    log.i('$_tag: Notification deleted');
    await stop();
    await super.onNotificationDeleted();
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'toggleShuffle':
        await toggleShuffle();
        break;
      case 'setRepeatMode':
        if (extras != null && extras.containsKey('mode')) {
          final mode = app_player_state.RepeatMode.values[extras['mode'] as int];
          await setAppRepeatMode(mode);
        }
        break;
      default:
        log.w('$_tag: Unknown custom action: $name');
    }
    await super.customAction(name, extras);
  }

  // Clean up resources
  Future<void> dispose() async {
    await _player.dispose();
    // The BaseAudioHandler will handle closing the customEvent PublishSubject
  }
}
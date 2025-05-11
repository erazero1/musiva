import 'package:musiva/features/songs/domain/entities/song.dart';

enum  PlaybackState {
  idle,
  loading,
  playing,
  paused,
  stopped,
  error,
}

enum RepeatMode {
  off,
  all,
  one,
}

class PlayerState {
  final PlaybackState playbackState;
  final List<Song> queue;         // Current and upcoming songs
  final List<Song> history;       // Previously played songs
  final int currentIndex;
  final Duration position;
  final Duration duration;
  final bool isShuffled;
  final RepeatMode repeatMode;
  final String? error;

  // The full queue including history, current, and upcoming songs
  List<Song> get fullQueue => [...history, ...queue];
  
  // The index in the full queue
  int get fullQueueIndex => history.length + currentIndex;

  Song? get currentSong => queue.isNotEmpty && currentIndex >= 0 && currentIndex < queue.length 
      ? queue[currentIndex] 
      : null;

  bool get hasNext => queue.isNotEmpty && 
      (repeatMode != RepeatMode.off || currentIndex < queue.length - 1);

  bool get hasPrevious => history.isNotEmpty || 
      (queue.isNotEmpty && currentIndex > 0) || 
      repeatMode != RepeatMode.off;

  PlayerState({
    this.playbackState = PlaybackState.idle,
    this.queue = const [],
    this.history = const [],
    this.currentIndex = -1,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isShuffled = false,
    this.repeatMode = RepeatMode.off,
    this.error,
  });

  PlayerState copyWith({
    PlaybackState? playbackState,
    List<Song>? queue,
    List<Song>? history,
    int? currentIndex,
    Duration? position,
    Duration? duration,
    bool? isShuffled,
    RepeatMode? repeatMode,
    String? error,
  }) {
    return PlayerState(
      playbackState: playbackState ?? this.playbackState,
      queue: queue ?? this.queue,
      history: history ?? this.history,
      currentIndex: currentIndex ?? this.currentIndex,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isShuffled: isShuffled ?? this.isShuffled,
      repeatMode: repeatMode ?? this.repeatMode,
      error: error ?? this.error,
    );
  }
}
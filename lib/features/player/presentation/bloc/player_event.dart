part of 'player_bloc.dart';

abstract class PlayerEvent {}

class InitPlayer extends PlayerEvent {}

class PlaySong extends PlayerEvent {
  final Song song;
  final bool clearQueue;

  PlaySong(this.song, {this.clearQueue = false});
}

class PlaySongAtIndex extends PlayerEvent {
  final int index;

  PlaySongAtIndex(this.index);
}

class PauseSong extends PlayerEvent {}

class ResumeSong extends PlayerEvent {}

class SeekTo extends PlayerEvent {
  final Duration position;

  SeekTo(this.position);
}

class NextSong extends PlayerEvent {}

class PreviousSong extends PlayerEvent {}

class ToggleShuffle extends PlayerEvent {}

class SetRepeatMode extends PlayerEvent {
  final RepeatMode mode;

  SetRepeatMode(this.mode);
}

class UpdatePosition extends PlayerEvent {
  final Duration position;

  UpdatePosition(this.position);
}

class SetQueue extends PlayerEvent {
  final List<Song> songs;
  final bool autoplay;

  SetQueue(this.songs, {this.autoplay = false});
}

class AddToQueue extends PlayerEvent {
  final Song song;
  final bool playIfEmpty;

  AddToQueue(this.song, {this.playIfEmpty = false});
}

class RemoveFromQueue extends PlayerEvent {
  final int index;

  RemoveFromQueue(this.index);
}

class ClearQueue extends PlayerEvent {}

class PlaybackError extends PlayerEvent {
  final String error;

  PlaybackError(this.error);
}

class StopPlayback extends PlayerEvent {}

class RefreshPlayerState extends PlayerEvent {}

class SongPlayedEvent extends PlayerEvent {
  final String songId;
  
  SongPlayedEvent(this.songId);
}
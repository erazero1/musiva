import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musiva/features/player/domain/entities/player_state.dart' as player_entities;
import 'package:musiva/features/player/presentation/bloc/player_bloc.dart';
import 'package:musiva/features/player/presentation/widgets/audio_waveform.dart';
import 'package:musiva/features/player/presentation/widgets/player_controls.dart';
import 'package:musiva/features/player/presentation/widgets/player_progress_bar.dart';
import 'package:musiva/features/player/presentation/widgets/queue_list.dart';

class FullPlayerPage extends StatefulWidget {
  const FullPlayerPage({super.key});

  @override
  State<FullPlayerPage> createState() => _FullPlayerPageState();
}

class _FullPlayerPageState extends State<FullPlayerPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _playPauseController;
  late Animation<double> _albumArtScaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize animation controller for play/pause transitions
    _playPauseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Animation for album art scaling effect
    _albumArtScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _playPauseController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Make sure the player is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayerBloc>().add(InitPlayer());
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _playPauseController.dispose();
    super.dispose();
  }
  
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
              duration: const Duration(seconds: 1),
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
        final currentSong = state.currentSong;
        
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              currentSong?.title ?? 'Now Playing',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Now Playing'),
                Tab(text: 'Queue'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildNowPlayingView(context, state),
              QueueList(
                queue: state.queue,
                currentIndex: state.currentIndex,
                onTap: (index) {
                  context.read<PlayerBloc>().add(PlaySongAtIndex(index));
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildNowPlayingView(BuildContext context, player_entities.PlayerState state) {
    final currentSong = state.currentSong;
    
    if (currentSong == null) {
      return const Center(
        child: Text('No song is currently playing'),
      );
    }
    
    return GestureDetector(
      // Add swipe gestures for next/previous
      onHorizontalDragEnd: (details) {
        // Swipe right to go to previous song
        if (details.primaryVelocity! > 0) {
          context.read<PlayerBloc>().add(PreviousSong());
        } 
        // Swipe left to go to next song
        else if (details.primaryVelocity! < 0) {
          context.read<PlayerBloc>().add(NextSong());
        }
      },
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(), // Prevent scroll interference with swipe
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            const SizedBox(height: 32),
            
            // Album artwork with animation
            Hero(
              tag: 'album_art_${currentSong.id}',
              child: AnimatedBuilder(
                animation: _albumArtScaleAnimation,
                builder: (context, child) {
                  // Update animation state based on playback state
                  if (state.playbackState == player_entities.PlaybackState.playing) {
                    _playPauseController.forward();
                  } else {
                    _playPauseController.reverse();
                  }
                  
                  return Transform.scale(
                    scale: _albumArtScaleAnimation.value,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.width * 0.8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(currentSong.artworkUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Song title and artist
            Text(
              currentSong.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              currentSong.artist,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            // Progress bar
            PlayerProgressBar(
              position: state.position,
              duration: state.duration,
              onSeek: (position) {
                context.read<PlayerBloc>().add(SeekTo(position));
              },
            ),
            
            const SizedBox(height: 16),
            
            // Audio waveform visualization
            AudioWaveform(
              isPlaying: state.playbackState == player_entities.PlaybackState.playing,
              color: Theme.of(context).primaryColor,
              height: 40,
              barCount: 30,
            ),
            
            const SizedBox(height: 16),
            
            // Playback controls
            PlayerControls(
              playbackState: state.playbackState,
              repeatMode: state.repeatMode,
              isShuffled: state.isShuffled,
              onPlay: () => context.read<PlayerBloc>().add(ResumeSong()),
              onPause: () => context.read<PlayerBloc>().add(PauseSong()),
              onNext: () => context.read<PlayerBloc>().add(NextSong()),
              onPrevious: () => context.read<PlayerBloc>().add(PreviousSong()),
              onToggleShuffle: () => context.read<PlayerBloc>().add(ToggleShuffle()),
              onSetRepeatMode: (mode) => context.read<PlayerBloc>().add(SetRepeatMode(mode)),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
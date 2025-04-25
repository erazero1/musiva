import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/library_bloc.dart';
import '../widgets/album_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../widgets/library_section_header.dart';
import '../widgets/playlist_card.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LibraryBloc()..add(const FetchLibrary()),
      child: const LibraryPageContent(),
    );
  }
}

class LibraryPageContent extends StatelessWidget {
  const LibraryPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        if (state.status == LibraryStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state.status == LibraryStatus.failure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!.failed_to_load_library_label),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<LibraryBloc>().add(const FetchLibrary());
                  },
                  child: Text(AppLocalizations.of(context)!.retry_label),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<LibraryBloc>().add(const FetchLibrary());
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Recently played
              SliverToBoxAdapter(
                child: LibrarySectionHeader(
                  title: AppLocalizations.of(context)!.recently_played_label,
                  onViewAll: () {
                    // TODO: Navigate to all recently played
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.recentSongs.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final song = state.recentSongs[index];
                      return AlbumCard(
                        imageUrl: song.artworkUrl,
                        title: song.title,
                        subtitle: song.artist,
                        onTap: () {
                          // TODO: Play the song
                        },
                      );
                    },
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: LibrarySectionHeader(
                  title: AppLocalizations.of(context)!.your_playlists_label,
                  onViewAll: () {
                    // TODO: Navigate to all playlists
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 260,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.playlists.length + 1,
                    // +1 for the "Create Playlist" card
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      // First item is "Create Playlist"
                      if (index == 0) {
                        return PlaylistCard(
                          isCreatePlaylist: true,
                          onTap: () {
                            // TODO: Show create playlist dialog
                          },
                        );
                      } else {
                        final playlist = state.playlists[index - 1];
                        return PlaylistCard(
                          imageUrl: playlist.coverUrl,
                          title: playlist.name,
                          songCount: playlist.songCount,
                          onTap: () {
                            // TODO: Navigate to playlist details
                          },
                        );
                      }
                    },
                  ),
                ),
              ),

              // Favorites
              SliverToBoxAdapter(
                child: LibrarySectionHeader(
                  title: AppLocalizations.of(context)!.favorites_label,
                  onViewAll: () {
                    // TODO: Navigate to all favorites
                  },
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= state.favorites.length) return null;
                    final song = state.favorites[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          song.artworkUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(song.title),
                      subtitle: Text(song.artist),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () {
                          // TODO: Remove from favorites
                        },
                      ),
                      onTap: () {
                        // TODO: Play the song
                      },
                    );
                  },
                  childCount:
                      state.favorites.length > 5 ? 5 : state.favorites.length,
                ),
              ),

              // Downloads
              SliverToBoxAdapter(
                child: LibrarySectionHeader(
                  title: AppLocalizations.of(context)!.downloads_label,
                  onViewAll: () {
                    // TODO: Navigate to all downloads
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 80),
                // Extra padding at the bottom for mini player
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= state.downloads.length) return null;
                      final song = state.downloads[index];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            song.artworkUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(song.title),
                        subtitle: Text(song.artist),
                        trailing: IconButton(
                          icon: const Icon(Icons.download_done),
                          onPressed: () {
                            // TODO: Show download options
                          },
                        ),
                        onTap: () {
                          // TODO: Play the song
                        },
                      );
                    },
                    childCount:
                        state.downloads.length > 5 ? 5 : state.downloads.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:musiva/features/player/presentation/bloc/player_bloc.dart';
import 'package:musiva/features/player/presentation/pages/full_player_page.dart';
import '../bloc/songs_bloc.dart';
import '../widgets/featured_carousel.dart';
import '../widgets/song_list_item.dart';
import '../widgets/category_selector.dart';

class SongsPage extends StatelessWidget {
  SongsPage({super.key});

  final sl = GetIt.instance;

  @override
  Widget build(BuildContext context) {
    // We need to ensure the SongsPage has access to both SongsBloc and PlayerBloc
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<SongsBloc>()..add(const FetchSongs()),
        ),
        // Use the existing PlayerBloc from the widget tree if available,
        // otherwise create a new one
        BlocProvider.value(
          value: BlocProvider.of<PlayerBloc>(context, listen: false),
        ),
      ],
      child: const SongsPageContent(),
    );
  }
}

class SongsPageContent extends StatefulWidget {
  const SongsPageContent({super.key});

  @override
  State<SongsPageContent> createState() => _SongsPageContentState();
}

class _SongsPageContentState extends State<SongsPageContent> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isNearBottom) {
      context.read<SongsBloc>().add(const LoadMoreSongs());
    }
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.search_songs_label,
                  border: InputBorder.none,
                ),
                autofocus: true,
                onChanged: (query) {
                  if (query.length >= 2) {
                    context.read<SongsBloc>().add(SearchSongs(query));
                  } else if (query.isEmpty) {
                    context.read<SongsBloc>().add(const ClearSearch());
                  }
                },
              )
            : Container(),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  context.read<SongsBloc>().add(const ClearSearch());
                }
              });
            },
          ),
        ],
      ),
      body: BlocBuilder<SongsBloc, SongsState>(
        builder: (context, state) {
          // Handle initial loading state
          if (state.status == SongsStatus.loading && state.songs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // Handle failure state
          if (state.status == SongsStatus.failure && state.songs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!.failed_to_load_songs_label),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SongsBloc>().add(const FetchSongs(refresh: true));
                    },
                    child: Text(AppLocalizations.of(context)!.retry_label),
                  ),
                ],
              ),
            );
          }
          
          // Handle search state
          if (_isSearching) {
            return _buildSearchResults(state);
          }
          
          // Main content
          return RefreshIndicator(
            onRefresh: () async {
              context.read<SongsBloc>().add(const FetchSongs(refresh: true));
            },
            child: Container(
              // Add a subtle background container for better content visibility
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Featured carousel
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: FeaturedCarousel(
                        items: state.featuredSongs.take(5).toList(),
                      ),
                    ),
                  ),

                  // Category selector
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: CategorySelector(
                        categories: [
                          AppLocalizations.of(context)!.all_label,
                          AppLocalizations.of(context)!.recent_label,
                          AppLocalizations.of(context)!.popular_label,
                          AppLocalizations.of(context)!.trending_label
                        ],
                        selectedCategory: state.selectedCategory,
                        onCategorySelected: (category) {
                          context.read<SongsBloc>().add(CategorySelected(category));
                        },
                      ),
                    ),
                  ),

                  // Section title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          state.selectedCategory,
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Song list
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= state.filteredSongs.length) {
                            return _buildLoaderIndicator();
                          }
                          
                          final song = state.filteredSongs[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SongListItem(
                              song: song,
                              onTap: () {
                                // Increment play count
                                context.read<SongsBloc>().add(SongPlayed(song.id));
                                
                                // Play the selected song and set it as the only song in the queue
                                context.read<PlayerBloc>().add(PlaySong(song, clearQueue: true));
                                
                                // Navigate to full player
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const FullPlayerPage(),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        childCount: state.filteredSongs.length + (state.hasReachedMax ? 0 : 1),
                      ),
                    ),
                  ),
              ],
            ),
          ));
        },
      ),
    );
  }
  
  Widget _buildSearchResults(SongsState state) {
    if (state.status == SongsStatus.searchLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state.searchQuery.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 80, color: Colors.white.withOpacity(0.7)),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.search_for_songs_label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    if (state.searchResults.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_off, size: 80, color: Colors.white.withOpacity(0.7)),
              const SizedBox(height: 16),
              Text(
                '${AppLocalizations.of(context)!.no_results_found_label} "${state.searchQuery}"',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                '${AppLocalizations.of(context)!.search_result_label}: "${state.searchQuery}"',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.searchResults.length,
              itemBuilder: (context, index) {
                final song = state.searchResults[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SongListItem(
                    song: song,
                    onTap: () {
                      // Increment play count
                      context.read<SongsBloc>().add(SongPlayed(song.id));
                      
                      // Play the selected song and set it as the only song in the queue
                      context.read<PlayerBloc>().add(PlaySong(song, clearQueue: true));
                      
                      // Navigate to full player
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const FullPlayerPage(),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoaderIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}

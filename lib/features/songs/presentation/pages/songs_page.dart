import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../bloc/songs_bloc.dart';
import '../widgets/featured_carousel.dart';
import '../widgets/song_list_item.dart';
import '../widgets/category_selector.dart';

class SongsPage extends StatelessWidget {
  SongsPage({super.key});

  final sl = GetIt.instance;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SongsBloc>()..add(const FetchSongs()),
      child: SongsPageContent(),
    );
  }
}

class SongsPageContent extends StatelessWidget {
  const SongsPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SongsBloc, SongsState>(
      builder: (context, state) {
        if (state.status == SongsStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state.status == SongsStatus.failure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Failed to load songs'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<SongsBloc>().add(const FetchSongs());
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<SongsBloc>().add(const FetchSongs());
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Featured carousel
              SliverToBoxAdapter(
                child: FeaturedCarousel(
                  items: state.featuredSongs.take(5).toList(),
                ),
              ),

              // Category selector
              SliverToBoxAdapter(
                child: CategorySelector(
                  categories: const ['All', 'Recent', 'Popular', 'Trending'],
                  selectedCategory: state.selectedCategory,
                  onCategorySelected: (category) {
                    context.read<SongsBloc>().add(CategorySelected(category));
                  },
                ),
              ),

              // Song list
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final song = state.filteredSongs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SongListItem(
                          song: song,
                          onTap: () {
                            // TODO: Play the selected song
                          },
                        ),
                      );
                    },
                    childCount: state.filteredSongs.length,
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
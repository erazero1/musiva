import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../library/presentation/pages/library_page.dart';
import '../../../songs/presentation/pages/songs_page.dart';
import '../bloc/navigation_bloc.dart';
import '../widgets/musiva_app_bar.dart';
import '../widgets/now_playing_mini_player.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NavigationBloc(),
      child: const HomePageContent(),
    );
  }
}

class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                MusivaAppBar(title: _getTitle(state.currentIndex)),

                // Main content area
                Expanded(
                  child: _buildPage(state.currentIndex),
                ),

                // Mini Player at the bottom
                const NowPlayingMiniPlayer(),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: state.currentIndex,
            onTap: (index) {
              context.read<NavigationBloc>().add(NavigationTabChanged(index));
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.music_note),
                label: 'Songs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music),
                label: 'Library',
              ),
            ],
            selectedItemColor: Theme.of(context).primaryColor,
            elevation: 8.0,
          ),
        );
      },
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Songs';
      case 1:
        return 'Library';
      default:
        return 'Musiva';
    }
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const SongsPage();
      case 1:
        return const LibraryPage();
      default:
        return const SongsPage();
    }
  }
}

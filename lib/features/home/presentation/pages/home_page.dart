import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musiva/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:musiva/features/song_upload/presentation/pages/upload_page.dart';
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
                MusivaAppBar(title: _getTitle(state.currentIndex, context)),

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
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.music_note),
                label: AppLocalizations.of(context)!.songs_label,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music),
                label: AppLocalizations.of(context)!.library_label,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.cloud_upload),
                label: AppLocalizations.of(context)!.upload_label,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: AppLocalizations.of(context)!.profile_label,
              ),
            ],
            selectedItemColor: Theme.of(context).primaryColor,
            elevation: 8.0,
          ),
        );
      },
    );
  }

  String _getTitle(int index, BuildContext context) {
    switch (index) {
      case 0:
        return AppLocalizations.of(context)!.songs_label;
      case 1:
        return AppLocalizations.of(context)!.library_label;
      case 2:
        return AppLocalizations.of(context)!.upload_label;
      case 3:
        return AppLocalizations.of(context)!.profile_label;
      default:
        return AppLocalizations.of(context)!.app_name;
    }
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return SongsPage();
      case 1:
        return const LibraryPage();
      case 2:
        return UploadSongPage();
      case 3:
        return const ProfilePage();
      default:
        return SongsPage();
    }
  }
}

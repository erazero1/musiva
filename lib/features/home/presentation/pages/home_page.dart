import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musiva/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:musiva/features/song_upload/presentation/pages/upload_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
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
    final authState = context.watch<AuthBloc>().state;
    final isGuest = authState is GuestAuthenticated;
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        final tabs = _getTabs(context, isGuest);
        final pages = _getPages(isGuest);

        final currentIndex = state.currentIndex.clamp(0, tabs.length - 1);
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                MusivaAppBar(
                  title: tabs[currentIndex].label ??
                      AppLocalizations.of(context)!.app_name,
                ),

                // Main content area
                Expanded(child: pages[currentIndex]),

                // Mini Player at the bottom
                const NowPlayingMiniPlayer(),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) {
              context.read<NavigationBloc>().add(NavigationTabChanged(index));
            },
            items: tabs,
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

  List<BottomNavigationBarItem> _getTabs(BuildContext context, bool isGuest) {
    final l10n = AppLocalizations.of(context)!;
    return [
      BottomNavigationBarItem(
        icon: const Icon(Icons.music_note),
        label: l10n.songs_label,
      ),
      if (!isGuest)
        BottomNavigationBarItem(
          icon: const Icon(Icons.library_music),
          label: l10n.library_label,
        ),
      if (!isGuest)
        BottomNavigationBarItem(
          icon: const Icon(Icons.cloud_upload),
          label: l10n.upload_label,
        ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person),
        label: l10n.profile_label,
      ),
    ];
  }

  List<Widget> _getPages(bool isGuest) {
    return [
      SongsPage(),
      if (!isGuest) const LibraryPage(),
      if (!isGuest) UploadSongPage(),
      const ProfilePage(),
    ];
  }
}

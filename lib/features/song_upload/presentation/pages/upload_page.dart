import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../bloc/song_upload_bloc.dart';
import '../widgets/upload_song_form.dart';

class UploadSongPage extends StatelessWidget {
  UploadSongPage({super.key});

  final sl = GetIt.instance;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SongUploadBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.upload_song_label),
        ),
        body: const UploadSongForm(),
      ),
    );
  }
}

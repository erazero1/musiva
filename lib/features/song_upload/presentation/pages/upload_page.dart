import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

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
          title: const Text('Upload Song'),
        ),
        body: const UploadSongForm(),
      ),
    );
  }
}

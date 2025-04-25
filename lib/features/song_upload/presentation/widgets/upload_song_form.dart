import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../bloc/song_upload_bloc.dart';

class UploadSongForm extends StatefulWidget {
  const UploadSongForm({super.key});

  @override
  State<UploadSongForm> createState() => _UploadSongFormState();
}

class _UploadSongFormState extends State<UploadSongForm> {
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _artworkUrlController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _artworkUrlController.dispose();
    super.dispose();
  }

  void _updateSongInfo() {
    context.read<SongUploadBloc>().add(
      UpdateSongInfo({
        'title': _titleController.text,
        'artist': _artistController.text,
        'artworkUrl': _artworkUrlController.text,
      }),
    );
  }

  Future<void> _selectAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      context.read<SongUploadBloc>().add(
        SelectAudioFile(result.files.first.path!),
      )  ;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SongUploadBloc, SongUploadState>(
      listener: (context, state) {
        if (state is SongUploadSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppLocalizations.of(context)!.song_label} "${state.song.title}" ${AppLocalizations.of(context)!.uploaded_successfully_label}')),
          );


          Navigator.of(context).pushReplacementNamed('/home');
        } else if (state is SongUploadFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppLocalizations.of(context)!.upload_failed_label}: ${state.message}')),
          );
          Navigator.of(context).pushReplacementNamed('/songs');

        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFilePicker(state),
              if (state is AudioFileSelected ||
                  state is SongInfoUpdated ||
                  state is SongUploading)
                _buildSongForm(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilePicker(SongUploadState state) {
    String? fileName;
    if (state is AudioFileSelected) {
      fileName = state.fileName;
    } else if (state is SongInfoUpdated) {
      fileName = state.fileName;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context)!.select_mp3_file_label,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (fileName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text('${AppLocalizations.of(context)!.selected_file_label}: $fileName'),
              ),
            ElevatedButton.icon(
              onPressed: state is SongUploading ? null : _selectAudioFile,
              icon: const Icon(Icons.audio_file),
              label: Text(AppLocalizations.of(context)!.browse_files_label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongForm(SongUploadState state) {
    bool isLoading = state is SongUploading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context)!.song_details_label,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.title_label,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _updateSongInfo(),
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _artistController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.artist_label,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _updateSongInfo(),
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _artworkUrlController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.artwork_url_label,
                border: OutlineInputBorder(),
                hintText: 'https://example.com/artwork.jpg',
              ),
              onChanged: (_) => _updateSongInfo(),
              enabled: !isLoading,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : () {
                context.read<SongUploadBloc>().add(UploadSong());
              },
              child: isLoading
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(AppLocalizations.of(context)!.uploading_label),
                ],
              )
                  : Text(AppLocalizations.of(context)!.upload_song_label),
            ),
          ],
        ),
      ),
    );
  }
}
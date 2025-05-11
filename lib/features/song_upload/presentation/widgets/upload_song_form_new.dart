import 'dart:io';
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
  String? _artworkFilePath;
  bool _useArtworkFile = false;

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _artworkUrlController.dispose();
    super.dispose();
  }

  void _updateSongInfo() {
    final Map<String, dynamic> songInfo = {
      'title': _titleController.text,
      'artist': _artistController.text,
    };

    if (_useArtworkFile && _artworkFilePath != null) {
      songInfo['artworkFilePath'] = _artworkFilePath;
    } else {
      songInfo['artworkUrl'] = _artworkUrlController.text;
    }

    context.read<SongUploadBloc>().add(
      UpdateSongInfo(songInfo),
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
      );
    }
  }

  Future<void> _selectArtworkFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _artworkFilePath = result.files.first.path!;
        _useArtworkFile = true;
      });
      _updateSongInfo();
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
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => _updateSongInfo(),
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _artistController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.artist_label,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => _updateSongInfo(),
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),
            
            // Artwork section
            Text(
              "Artwork",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            // Toggle between URL and file upload
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text("URL"),
                    value: false,
                    groupValue: _useArtworkFile,
                    onChanged: isLoading ? null : (value) {
                      setState(() {
                        _useArtworkFile = value!;
                      });
                      _updateSongInfo();
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text("Upload Image"),
                    value: true,
                    groupValue: _useArtworkFile,
                    onChanged: isLoading ? null : (value) {
                      setState(() {
                        _useArtworkFile = value!;
                      });
                      _updateSongInfo();
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Show either URL input or file upload based on selection
            if (!_useArtworkFile)
              TextFormField(
                controller: _artworkUrlController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.artwork_url_label,
                  border: const OutlineInputBorder(),
                  hintText: 'https://example.com/artwork.jpg',
                ),
                onChanged: (_) => _updateSongInfo(),
                enabled: !isLoading,
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_artworkFilePath != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_artworkFilePath!),
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : _selectArtworkFile,
                    icon: const Icon(Icons.image),
                    label: Text(_artworkFilePath == null 
                      ? "Select Cover Image" 
                      : "Change Cover Image"),
                  ),
                ],
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
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
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
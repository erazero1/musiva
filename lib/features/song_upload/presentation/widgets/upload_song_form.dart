import 'dart:io';
import 'dart:typed_data';
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
  
  // Track validation state
  bool _titleError = false;
  bool _artistError = false;

  @override
  void initState() {
    super.initState();
    // Initialize validation state
    _titleError = true;  // Start with validation errors since fields are empty
    _artistError = true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _artworkUrlController.dispose();
    super.dispose();
  }

  void _updateSongInfo() {
    // Validate fields
    setState(() {
      _titleError = _titleController.text.isEmpty;
      _artistError = _artistController.text.isEmpty;
    });
    
    final Map<String, dynamic> songInfo = {
      'title': _titleController.text,
      'artist': _artistController.text,
    };

    // Artwork is optional - if provided, include it in the song info
    if (_useArtworkFile && _artworkFilePath != null) {
      songInfo['artworkFilePath'] = _artworkFilePath;
    } else if (_artworkUrlController.text.isNotEmpty) {
      songInfo['artworkUrl'] = _artworkUrlController.text;
    }
    // If no artwork is provided, the default placeholder will be used

    // Only send the update if we have the required fields
    if (!_titleError && !_artistError) {
      context.read<SongUploadBloc>().add(
        UpdateSongInfo(songInfo),
      );
    }
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
          
          // Only navigate away for non-validation errors
          // Validation errors like "Artist name cannot be empty" should allow the user to fix the form
          if (!state.message.contains("cannot be empty") && 
              !state.message.contains("incomplete")) {
            Navigator.of(context).pushReplacementNamed('/songs');
          }
        } else if (state is AudioFileSelected && state.hasMetadata) {
          // Pre-fill form fields with metadata if available
          if (state.metadata['title'] != null) {
            _titleController.text = state.metadata['title'];
            setState(() {
              _titleError = _titleController.text.isEmpty;
            });
          }
          
          if (state.metadata['artist'] != null) {
            _artistController.text = state.metadata['artist'];
            setState(() {
              _artistError = _artistController.text.isEmpty;
            });
          }
          
          // Update song info with the metadata
          _updateSongInfo();
          
          // Show a snackbar to inform the user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Metadata found in the audio file. You can edit the information if needed.'),
              duration: const Duration(seconds: 3),
            ),
          );
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
    
    // Check if we have embedded artwork from metadata
    bool hasEmbeddedArtwork = false;
    Uint8List? embeddedArtwork;
    
    if (state is AudioFileSelected && state.metadata['hasPicture'] == true) {
      hasEmbeddedArtwork = true;
      embeddedArtwork = state.metadata['picture'];
    }

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
            if (state is AudioFileSelected && state.hasMetadata)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  AppLocalizations.of(context)!.metadata_found_label,
                  style: TextStyle(
                    color: Colors.green[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '${AppLocalizations.of(context)!.title_label} *',
                border: const OutlineInputBorder(),
                hintText: AppLocalizations.of(context)!.enter_song_title_hint,
                errorText: _titleError ? AppLocalizations.of(context)!.song_title_required_error : null,
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _titleError = value.isEmpty;
                });
                _updateSongInfo();
              },
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _artistController,
              decoration: InputDecoration(
                labelText: '${AppLocalizations.of(context)!.artist_label} *',
                border: const OutlineInputBorder(),
                hintText: AppLocalizations.of(context)!.enter_artist_name_hint,
                errorText: _artistError ? AppLocalizations.of(context)!.artist_name_required_error : null,
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _artistError = value.isEmpty;
                });
                _updateSongInfo();
              },
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),
            
            // Artwork section - Fixed overflow by using Column instead of Row
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.artwork_optional_label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (hasEmbeddedArtwork)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Chip(
                          label: Text(AppLocalizations.of(context)!.from_metadata_label),
                          backgroundColor: Colors.green[100],
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    AppLocalizations.of(context)!.default_cover_note,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Toggle between URL, file upload, and embedded artwork
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: Text(AppLocalizations.of(context)!.url_label),
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
                    title: Text(AppLocalizations.of(context)!.upload_image_label),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _artworkUrlController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.artwork_url_label,
                      border: const OutlineInputBorder(),
                      hintText: AppLocalizations.of(context)!.artwork_url_hint,
                    ),
                    onChanged: (_) => _updateSongInfo(),
                    enabled: !isLoading,
                  ),
                  // Show embedded artwork if available
                  if (hasEmbeddedArtwork && embeddedArtwork != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.embedded_artwork_found_label,
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              embeddedArtwork!,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.copy),
                            label: const Text("Use this artwork"),
                            onPressed: isLoading ? null : () {
                              setState(() {
                                _useArtworkFile = true;
                                // We'll need to save the embedded artwork to a temporary file
                                // This would be implemented in a real app
                                // For now, just show a message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context)!.using_embedded_artwork_message),
                                  ),
                                );
                              });
                              _updateSongInfo();
                            },
                          ),
                        ],
                      ),
                    )
                  else if (_artworkUrlController.text.isEmpty)
                    // Show default placeholder preview when no URL is entered
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.default_placeholder_used_label,
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/placeholder_album.jpg',
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
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
                    )
                  else if (hasEmbeddedArtwork && embeddedArtwork != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          embeddedArtwork!,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    // Show default placeholder preview
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/placeholder_album.jpg',
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              "Default placeholder image",
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : _selectArtworkFile,
                    icon: const Icon(Icons.image),
                    label: Text(_artworkFilePath == null && !hasEmbeddedArtwork
                      ? "Select Cover Image" 
                      : "Change Cover Image"),
                  ),
                ],
              ),
            
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading || _titleError || _artistError 
                ? null 
                : () {
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
            if (_titleError || _artistError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Please fill in all required fields marked with *",
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
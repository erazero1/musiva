import 'package:flutter/material.dart';

class AudioFilePicker extends StatelessWidget {
  final String? fileName;
  final bool isLoading;
  final Function() onPickFile;

  const AudioFilePicker({
    super.key,
    this.fileName,
    required this.onPickFile,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select MP3 File',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (fileName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text('Selected file: $fileName'),
              ),
            ElevatedButton.icon(
              onPressed: isLoading ? null : onPickFile,
              icon: const Icon(Icons.audio_file),
              label: const Text('Browse Files'),
            ),
          ],
        ),
      ),
    );
  }
}
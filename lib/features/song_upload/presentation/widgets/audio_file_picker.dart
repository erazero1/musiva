import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
              onPressed: isLoading ? null : onPickFile,
              icon: const Icon(Icons.audio_file),
              label: Text(AppLocalizations.of(context)!.browse_files_label),
            ),
          ],
        ),
      ),
    );
  }
}
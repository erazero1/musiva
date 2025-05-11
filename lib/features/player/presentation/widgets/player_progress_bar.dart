import 'package:flutter/material.dart';

class PlayerProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final Function(Duration) onSeek;

  const PlayerProgressBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
            activeTrackColor: Theme.of(context).primaryColor,
            inactiveTrackColor: Colors.grey[300],
            thumbColor: Theme.of(context).primaryColor,
            overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
          ),
          child: Slider(
            min: 0.0,
            max: duration.inMilliseconds.toDouble(),
            value: position.inMilliseconds.toDouble().clamp(
              0.0,
              duration.inMilliseconds.toDouble(),
            ),
            onChanged: (value) {
              onSeek(Duration(milliseconds: value.round()));
            },
          ),
        ),
        
        // Time indicators
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                _formatDuration(duration),
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
import 'dart:math';
import 'package:flutter/material.dart';

class AudioWaveform extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final double height;
  final int barCount;

  const AudioWaveform({
    super.key,
    required this.isPlaying,
    this.color = Colors.blue,
    this.height = 40,
    this.barCount = 20,
  });

  @override
  State<AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveform> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<double> _barHeights;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    
    // Generate random bar heights
    _generateBarHeights();
    
    // Start animation if playing
    if (widget.isPlaying) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AudioWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update animation state when isPlaying changes
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _generateBarHeights() {
    _barHeights = List.generate(
      widget.barCount,
      (_) => 0.2 + _random.nextDouble() * 0.8,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              widget.barCount,
              (index) {
                // Calculate dynamic height based on animation
                double dynamicHeight = widget.isPlaying
                    ? _barHeights[index] * (0.5 + 0.5 * sin(index + _animationController.value * pi))
                    : _barHeights[index] * 0.5;
                
                return Container(
                  width: 3,
                  height: widget.height * dynamicHeight,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
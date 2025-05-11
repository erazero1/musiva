import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:musiva/core/utils/logger.dart';
import 'package:musiva/features/player/data/services/audio_handler.dart';

class AudioServiceProvider {
  static final AudioServiceProvider _instance = AudioServiceProvider._internal();
  static const String _tag = 'AudioServiceProvider';
  
  MusivaAudioHandler? _audioHandler;
  bool _isInitializing = false;
  
  factory AudioServiceProvider() {
    return _instance;
  }
  
  AudioServiceProvider._internal();
  
  Future<MusivaAudioHandler> getAudioHandler() async {
    if (_audioHandler != null) {
      return _audioHandler!;
    }
    
    // Prevent multiple simultaneous initializations
    if (_isInitializing) {
      // Wait until initialization is complete
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_audioHandler != null) {
        return _audioHandler!;
      }
    }
    
    try {
      _isInitializing = true;
      log.i('$_tag: Initializing audio handler');
      _audioHandler = await _initAudioService();
      log.i('$_tag: Audio handler initialized');
      return _audioHandler!;
    } catch (e, stackTrace) {
      log.e('$_tag: Error initializing audio handler', e, stackTrace);
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }
  
  Future<MusivaAudioHandler> _initAudioService() async {
    try {
      // We'll use a try-catch approach instead of checking connected property
      // If AudioService is already initialized, init() will throw an assertion error
      return await AudioService.init<MusivaAudioHandler>(
        builder: () => MusivaAudioHandler(),
        config: AudioServiceConfig(
          androidNotificationChannelId: 'com.erazero1.musiva.channel.audio',
          androidNotificationChannelName: 'Musiva Music Player',
          androidNotificationOngoing: false,
          androidStopForegroundOnPause: false,
          androidNotificationIcon: 'drawable/ic_notification',
          notificationColor: const Color(0xFF2196F3),
        ),
      );
    } catch (e) {
      // If we get the specific assertion error about _cacheManager not being null,
      // it means AudioService is already initialized
      if (e.toString().contains('_cacheManager == null')) {
        log.w('$_tag: AudioService is already initialized. Creating a new handler instance.');
        // Since we can't access the existing handler directly, create a new one
        // The underlying audio service will still be the same
        return MusivaAudioHandler();
      } else {
        // For other errors, rethrow
        rethrow;
      }
    }
  }
  
  Future<void> dispose() async {
    if (_audioHandler != null) {
      await _audioHandler!.dispose();
      _audioHandler = null;
    }
  }
}
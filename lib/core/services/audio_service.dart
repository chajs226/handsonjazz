import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../../data/models/audio_state.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final StreamController<AudioState> _stateController = StreamController<AudioState>.broadcast();

  AudioState _currentState = const AudioState();
  LoopData? _currentLoop;

  Stream<AudioState> get stateStream => _stateController.stream;
  AudioState get currentState => _currentState;

  AudioService() {
    _initialize();
  }

  void _initialize() {
    // Position stream
    _audioPlayer.positionStream.listen((position) {
      _updateState(_currentState.copyWith(currentPosition: position));
      _checkLoop(position);
    });

    // Duration stream
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        _updateState(_currentState.copyWith(totalDuration: duration));
      }
    });

    // Player state stream
    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final isLoading = playerState.processingState == ProcessingState.loading ||
                       playerState.processingState == ProcessingState.buffering;
      
      _updateState(_currentState.copyWith(
        isPlaying: isPlaying,
        isLoading: isLoading,
      ));
    });
  }

  void _updateState(AudioState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  void _checkLoop(Duration position) {
    if (_currentLoop != null && _currentLoop!.isEnabled) {
      if (position >= _currentLoop!.endTime) {
        _audioPlayer.seek(_currentLoop!.startTime);
      }
    }
  }

  Future<void> loadAudio(String audioUrl) async {
    try {
      _updateState(_currentState.copyWith(isLoading: true, error: null));
      await _audioPlayer.setAsset(audioUrl);
      _updateState(_currentState.copyWith(isLoading: false));
    } catch (e) {
      _updateState(_currentState.copyWith(
        isLoading: false,
        error: 'Failed to load audio: $e',
      ));
    }
  }

  Future<void> play() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      _updateState(_currentState.copyWith(error: 'Failed to play: $e'));
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      _updateState(_currentState.copyWith(error: 'Failed to pause: $e'));
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.seek(Duration.zero);
    } catch (e) {
      _updateState(_currentState.copyWith(error: 'Failed to stop: $e'));
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      _updateState(_currentState.copyWith(error: 'Failed to seek: $e'));
    }
  }

  Future<void> setSpeed(double speed) async {
    try {
      await _audioPlayer.setSpeed(speed);
      _updateState(_currentState.copyWith(playbackSpeed: speed));
    } catch (e) {
      _updateState(_currentState.copyWith(error: 'Failed to set speed: $e'));
    }
  }

  void setLoop(LoopData? loop) {
    _currentLoop = loop;
    _updateState(_currentState.copyWith(loop: loop));
  }

  void dispose() {
    _audioPlayer.dispose();
    _stateController.close();
  }
}

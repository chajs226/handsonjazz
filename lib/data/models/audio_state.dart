import 'package:equatable/equatable.dart';

class AudioState extends Equatable {
  final bool isPlaying;
  final bool isLoading;
  final Duration currentPosition;
  final Duration totalDuration;
  final double playbackSpeed;
  final LoopData? loop;
  final String? error;

  const AudioState({
    this.isPlaying = false,
    this.isLoading = false,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.playbackSpeed = 1.0,
    this.loop,
    this.error,
  });

  AudioState copyWith({
    bool? isPlaying,
    bool? isLoading,
    Duration? currentPosition,
    Duration? totalDuration,
    double? playbackSpeed,
    LoopData? loop,
    String? error,
  }) {
    return AudioState(
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      loop: loop ?? this.loop,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        isPlaying,
        isLoading,
        currentPosition,
        totalDuration,
        playbackSpeed,
        loop,
        error,
      ];
}

class LoopData extends Equatable {
  final Duration startTime;
  final Duration endTime;
  final bool isEnabled;

  const LoopData({
    required this.startTime,
    required this.endTime,
    this.isEnabled = true,
  });

  @override
  List<Object?> get props => [startTime, endTime, isEnabled];
}

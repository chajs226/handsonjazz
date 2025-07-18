import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/timing_service.dart';
import '../../data/models/audio_state.dart';
import '../../data/models/song.dart';

// Events
abstract class AudioPlayerEvent extends Equatable {
  const AudioPlayerEvent();

  @override
  List<Object> get props => [];
}

class LoadSong extends AudioPlayerEvent {
  final Song song;

  const LoadSong(this.song);

  @override
  List<Object> get props => [song];
}

class PlayAudio extends AudioPlayerEvent {}

class PauseAudio extends AudioPlayerEvent {}

class StopAudio extends AudioPlayerEvent {}

class SeekAudio extends AudioPlayerEvent {
  final Duration position;

  const SeekAudio(this.position);

  @override
  List<Object> get props => [position];
}

class SetPlaybackSpeed extends AudioPlayerEvent {
  final double speed;

  const SetPlaybackSpeed(this.speed);

  @override
  List<Object> get props => [speed];
}

class SetLoop extends AudioPlayerEvent {
  final LoopData? loop;

  const SetLoop(this.loop);

  @override
  List<Object> get props => [loop ?? ''];
}

class SetSectionLoop extends AudioPlayerEvent {
  final Duration startTime;
  final Duration endTime;

  const SetSectionLoop(this.startTime, this.endTime);

  @override
  List<Object> get props => [startTime, endTime];
}

class ClearSectionLoop extends AudioPlayerEvent {}

class AudioStateChanged extends AudioPlayerEvent {
  final AudioState audioState;

  const AudioStateChanged(this.audioState);

  @override
  List<Object> get props => [audioState];
}

// State
class AudioPlayerState extends Equatable {
  final AudioState audioState;
  final Song? currentSong;
  final String? currentChord;
  final Duration? sectionLoopStart;
  final Duration? sectionLoopEnd;

  const AudioPlayerState({
    this.audioState = const AudioState(),
    this.currentSong,
    this.currentChord,
    this.sectionLoopStart,
    this.sectionLoopEnd,
  });

  AudioPlayerState copyWith({
    AudioState? audioState,
    Song? currentSong,
    String? currentChord,
    Duration? sectionLoopStart,
    Duration? sectionLoopEnd,
    bool clearSectionLoop = false,
  }) {
    return AudioPlayerState(
      audioState: audioState ?? this.audioState,
      currentSong: currentSong ?? this.currentSong,
      currentChord: currentChord ?? this.currentChord,
      sectionLoopStart: clearSectionLoop ? null : (sectionLoopStart ?? this.sectionLoopStart),
      sectionLoopEnd: clearSectionLoop ? null : (sectionLoopEnd ?? this.sectionLoopEnd),
    );
  }

  bool get hasSectionLoop => sectionLoopStart != null && sectionLoopEnd != null;

  @override
  List<Object?> get props => [audioState, currentSong, currentChord, sectionLoopStart, sectionLoopEnd];
}

// BLoC
class AudioPlayerBloc extends Bloc<AudioPlayerEvent, AudioPlayerState> {
  final AudioService _audioService;
  final TimingService _timingService;
  StreamSubscription? _audioStateSubscription;
  StreamSubscription? _chordSubscription;

  AudioPlayerBloc({
    required AudioService audioService,
    required TimingService timingService,
  })  : _audioService = audioService,
        _timingService = timingService,
        super(const AudioPlayerState()) {
    
    on<LoadSong>(_onLoadSong);
    on<PlayAudio>(_onPlayAudio);
    on<PauseAudio>(_onPauseAudio);
    on<StopAudio>(_onStopAudio);
    on<SeekAudio>(_onSeekAudio);
    on<SetPlaybackSpeed>(_onSetPlaybackSpeed);
    on<SetLoop>(_onSetLoop);
    on<SetSectionLoop>(_onSetSectionLoop);
    on<ClearSectionLoop>(_onClearSectionLoop);
    on<AudioStateChanged>(_onAudioStateChanged);

    _audioStateSubscription = _audioService.stateStream.listen((audioState) {
      add(AudioStateChanged(audioState));
      
      // Check section loop
      if (state.hasSectionLoop && 
          state.sectionLoopEnd != null && 
          audioState.currentPosition >= state.sectionLoopEnd!) {
        _audioService.seek(state.sectionLoopStart!);
      }
      
      // Update timing service with current position
      final currentSong = state.currentSong;
      if (currentSong != null) {
        _timingService.updatePosition(audioState.currentPosition, currentSong);
      }
    });

    _chordSubscription = _timingService.currentChordStream.listen((chord) {
      emit(state.copyWith(currentChord: chord));
    });
  }

  Future<void> _onLoadSong(LoadSong event, Emitter<AudioPlayerState> emit) async {
    emit(state.copyWith(currentSong: event.song));
    await _audioService.loadAudio(event.song.audioUrl);
  }

  Future<void> _onPlayAudio(PlayAudio event, Emitter<AudioPlayerState> emit) async {
    await _audioService.play();
  }

  Future<void> _onPauseAudio(PauseAudio event, Emitter<AudioPlayerState> emit) async {
    await _audioService.pause();
  }

  Future<void> _onStopAudio(StopAudio event, Emitter<AudioPlayerState> emit) async {
    await _audioService.stop();
  }

  Future<void> _onSeekAudio(SeekAudio event, Emitter<AudioPlayerState> emit) async {
    await _audioService.seek(event.position);
  }

  Future<void> _onSetPlaybackSpeed(SetPlaybackSpeed event, Emitter<AudioPlayerState> emit) async {
    await _audioService.setSpeed(event.speed);
  }

  void _onSetLoop(SetLoop event, Emitter<AudioPlayerState> emit) {
    _audioService.setLoop(event.loop);
  }

  void _onSetSectionLoop(SetSectionLoop event, Emitter<AudioPlayerState> emit) {
    emit(state.copyWith(
      sectionLoopStart: event.startTime,
      sectionLoopEnd: event.endTime,
    ));
  }

  void _onClearSectionLoop(ClearSectionLoop event, Emitter<AudioPlayerState> emit) {
    emit(state.copyWith(clearSectionLoop: true));
  }

  void _onAudioStateChanged(AudioStateChanged event, Emitter<AudioPlayerState> emit) {
    emit(state.copyWith(audioState: event.audioState));
  }

  @override
  Future<void> close() {
    _audioStateSubscription?.cancel();
    _chordSubscription?.cancel();
    return super.close();
  }
}

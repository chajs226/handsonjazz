import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/services/timing_service.dart';
import '../../data/models/voicing_data.dart';

// State
class PianoRollState extends Equatable {
  final VoicingData? currentVoicing;
  final List<int> activeNotes; // Currently pressed notes

  const PianoRollState({
    this.currentVoicing,
    this.activeNotes = const [],
  });

  PianoRollState copyWith({
    VoicingData? currentVoicing,
    List<int>? activeNotes,
  }) {
    return PianoRollState(
      currentVoicing: currentVoicing ?? this.currentVoicing,
      activeNotes: activeNotes ?? this.activeNotes,
    );
  }

  @override
  List<Object?> get props => [currentVoicing, activeNotes];
}

// Cubit
class PianoRollCubit extends Cubit<PianoRollState> {
  final TimingService _timingService;
  StreamSubscription? _voicingSubscription;

  PianoRollCubit({required TimingService timingService})
      : _timingService = timingService,
        super(const PianoRollState()) {
    
    _voicingSubscription = _timingService.currentVoicingStream.listen((voicing) {
      if (voicing != null) {
        final allNotes = [...voicing.leftHand, ...voicing.rightHand];
        emit(state.copyWith(
          currentVoicing: voicing,
          activeNotes: allNotes,
        ));
      } else {
        emit(state.copyWith(
          currentVoicing: null,
          activeNotes: [],
        ));
      }
    });
  }

  void clearActiveNotes() {
    emit(state.copyWith(activeNotes: []));
  }

  @override
  Future<void> close() {
    _voicingSubscription?.cancel();
    return super.close();
  }
}

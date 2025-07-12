import 'dart:async';
import '../../data/models/song.dart';
import '../../data/models/voicing_data.dart';

class TimingService {
  final StreamController<String> _currentChordController = StreamController<String>.broadcast();
  final StreamController<VoicingData?> _currentVoicingController = StreamController<VoicingData?>.broadcast();

  Stream<String> get currentChordStream => _currentChordController.stream;
  Stream<VoicingData?> get currentVoicingStream => _currentVoicingController.stream;

  String? _currentChord;
  VoicingData? _currentVoicing;

  String? get currentChord => _currentChord;
  VoicingData? get currentVoicing => _currentVoicing;

  void updatePosition(Duration position, Song song) {
    // Find the current chord based on position
    String? newChord;
    VoicingData? newVoicing;

    // Get all timing keys and sort them
    final chordKeys = song.chordProgression.keys.map((k) => double.parse(k)).toList()..sort();

    // Find current chord
    for (int i = chordKeys.length - 1; i >= 0; i--) {
      if (position.inSeconds >= chordKeys[i]) {
        newChord = song.chordProgression[chordKeys[i].toString()];
        break;
      }
    }

    // Find current voicing based on the current chord
    if (newChord != null && song.voicings.containsKey(newChord)) {
      newVoicing = song.voicings[newChord];
    }

    // Update if changed
    if (newChord != _currentChord) {
      _currentChord = newChord;
      if (newChord != null) {
        _currentChordController.add(newChord);
      }
    }

    if (newVoicing != _currentVoicing) {
      _currentVoicing = newVoicing;
      _currentVoicingController.add(newVoicing);
    }
  }

  List<ChordTiming> getChordTimings(Song song) {
    return song.chordProgression.entries.map((entry) {
      final seconds = double.parse(entry.key);
      return ChordTiming(
        time: Duration(milliseconds: (seconds * 1000).round()),
        chord: entry.value,
      );
    }).toList()..sort((a, b) => a.time.compareTo(b.time));
  }

  void dispose() {
    _currentChordController.close();
    _currentVoicingController.close();
  }
}

class ChordTiming {
  final Duration time;
  final String chord;

  ChordTiming({required this.time, required this.chord});
}

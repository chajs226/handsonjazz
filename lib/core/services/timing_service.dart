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
    if (newChord != null) {
      newVoicing = _findVoicingForChord(newChord, song.voicings);
      
      // 디버깅: 코드 찾기 실패 시 로그
      if (newVoicing == null) {
        print('Warning: No voicing found for chord "$newChord"');
        print('Available voicings: ${song.voicings.keys.toList()}');
      }
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

  VoicingData? _findVoicingForChord(String chord, Map<String, VoicingData> voicings) {
    // 1. 정확한 코드명으로 찾기
    if (voicings.containsKey(chord)) {
      return voicings[chord];
    }
    
    // 2. 복합 코드의 경우 각 코드를 순서대로 시도
    if (chord.contains(' ')) {
      final chordParts = chord.split(' ');
      for (final part in chordParts) {
        if (voicings.containsKey(part)) {
          return voicings[part];
        }
        
        // 각 파트에 대해 기본 코드도 시도
        final basePart = _getBaseChord(part);
        if (voicings.containsKey(basePart)) {
          return voicings[basePart];
        }
      }
    } else {
      // 3. 단일 코드의 경우 기본 코드로 변환하여 찾기
      final baseChord = _getBaseChord(chord);
      if (voicings.containsKey(baseChord)) {
        return voicings[baseChord];
      }
    }
    
    return null;
  }

  String _getBaseChord(String chord) {
    // 코드 변형 제거하여 기본 코드 반환
    // 예: "Dm7b5" -> "Dm7", "G7b9" -> "G7"
    
    // 일반적인 변형 패턴들 제거
    final variations = ['b5', 'b9', '#5', '#9', '#11', 'sus2', 'sus4', 'add9', 'add11'];
    String baseChord = chord;
    
    for (final variation in variations) {
      baseChord = baseChord.replaceAll(variation, '');
    }
    
    return baseChord;
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

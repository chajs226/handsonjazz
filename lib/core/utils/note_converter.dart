import 'dart:math';

/// 주파수와 계이름 간의 변환을 담당하는 유틸리티 클래스
class NoteConverter {
  // A4 = 440Hz를 기준으로 한 12-TET (Twelve-tone equal temperament)
  static const double a4Frequency = 440.0;
  static const int a4MidiNote = 69;
  
  // 계이름 (한국어)
  static const List<String> noteNamesKorean = [
    '도', '도#', '레', '레#', '미', '파', '파#', '솔', '솔#', '라', '라#', '시'
  ];
  
  // 계이름 (영어)
  static const List<String> noteNamesEnglish = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  /// 주파수를 MIDI 노트 번호로 변환
  static double frequencyToMidiNote(double frequency) {
    if (frequency <= 0) return -1;
    return 12 * (log(frequency / a4Frequency) / ln2) + a4MidiNote;
  }

  /// MIDI 노트 번호를 주파수로 변환
  static double midiNoteToFrequency(double midiNote) {
    return a4Frequency * pow(2, (midiNote - a4MidiNote) / 12);
  }

  /// 주파수를 가장 가까운 계이름으로 변환 (한국어)
  static NoteInfo frequencyToNoteKorean(double frequency) {
    final midiNote = frequencyToMidiNote(frequency);
    final roundedMidiNote = midiNote.round();
    final cents = ((midiNote - roundedMidiNote) * 100).round();
    
    final octave = (roundedMidiNote / 12).floor() - 1;
    final noteIndex = roundedMidiNote % 12;
    
    return NoteInfo(
      noteName: noteNamesKorean[noteIndex],
      octave: octave,
      frequency: frequency,
      midiNote: roundedMidiNote,
      cents: cents,
      isSharp: noteNamesKorean[noteIndex].contains('#'),
    );
  }

  /// 주파수를 가장 가까운 계이름으로 변환 (영어)
  static NoteInfo frequencyToNoteEnglish(double frequency) {
    final midiNote = frequencyToMidiNote(frequency);
    final roundedMidiNote = midiNote.round();
    final cents = ((midiNote - roundedMidiNote) * 100).round();
    
    final octave = (roundedMidiNote / 12).floor() - 1;
    final noteIndex = roundedMidiNote % 12;
    
    return NoteInfo(
      noteName: noteNamesEnglish[noteIndex],
      octave: octave,
      frequency: frequency,
      midiNote: roundedMidiNote,
      cents: cents,
      isSharp: noteNamesEnglish[noteIndex].contains('#'),
    );
  }

  /// 피치 프레임들을 음표 이벤트로 변환
  static List<NoteEvent> pitchFramesToNoteEvents(
    List<dynamic> pitchFrames, {
    double minDuration = 0.1, // 최소 음표 길이 (초)
    int centThreshold = 25,   // 같은 음으로 간주할 센트 임계값
  }) {
    if (pitchFrames.isEmpty) return [];
    
    final List<NoteEvent> noteEvents = [];
    NoteInfo? currentNote;
    double? noteStartTime;
    
    for (int i = 0; i < pitchFrames.length; i++) {
      final frame = pitchFrames[i];
      final frequency = frame['frequency'] as double;
      final timeStamp = frame['timeStamp'] as double;
      final confidence = frame['confidence'] as double;
      
      // 신뢰도가 낮으면 무시
      if (confidence < 0.5) {
        if (currentNote != null && noteStartTime != null) {
          _finalizeNoteEvent(noteEvents, currentNote, noteStartTime, timeStamp, minDuration);
          currentNote = null;
          noteStartTime = null;
        }
        continue;
      }
      
      final noteInfo = frequencyToNoteKorean(frequency);
      
      if (currentNote == null) {
        // 새로운 음표 시작
        currentNote = noteInfo;
        noteStartTime = timeStamp;
      } else {
        // 현재 음표와 비교
        final centDifference = (noteInfo.midiNote - currentNote.midiNote) * 100 + 
                              noteInfo.cents - currentNote.cents;
        
        if (centDifference.abs() > centThreshold) {
          // 다른 음표로 변경
          _finalizeNoteEvent(noteEvents, currentNote, noteStartTime!, timeStamp, minDuration);
          currentNote = noteInfo;
          noteStartTime = timeStamp;
        }
      }
    }
    
    // 마지막 음표 처리
    if (currentNote != null && noteStartTime != null) {
      final lastFrame = pitchFrames.last;
      final endTime = lastFrame['timeStamp'] as double;
      _finalizeNoteEvent(noteEvents, currentNote, noteStartTime, endTime, minDuration);
    }
    
    return noteEvents;
  }

  static void _finalizeNoteEvent(
    List<NoteEvent> noteEvents,
    NoteInfo noteInfo,
    double startTime,
    double endTime,
    double minDuration,
  ) {
    final duration = endTime - startTime;
    if (duration >= minDuration) {
      noteEvents.add(NoteEvent(
        noteInfo: noteInfo,
        startTime: startTime,
        endTime: endTime,
        duration: duration,
      ));
    }
  }

  /// 음계 정보를 분석 (조성, 스케일 등)
  static ScaleAnalysis analyzeScale(List<NoteEvent> noteEvents) {
    final Map<int, int> noteFrequency = {};
    
    // 각 음의 출현 빈도 계산
    for (final event in noteEvents) {
      final noteClass = event.noteInfo.midiNote % 12;
      noteFrequency[noteClass] = (noteFrequency[noteClass] ?? 0) + 1;
    }
    
    // 가장 많이 나온 음들을 기준으로 조성 추정
    final sortedNotes = noteFrequency.entries.toList()
      ..sort((MapEntry<int, int> a, MapEntry<int, int> b) => b.value.compareTo(a.value));
    
    // 장조/단조 판별을 위한 간단한 휴리스틱
    final mostCommonNote = sortedNotes.isNotEmpty ? sortedNotes.first.key : 0;
    final scaleName = _determineScaleName(noteFrequency, mostCommonNote);
    
    return ScaleAnalysis(
      tonicNote: noteNamesKorean[mostCommonNote],
      scaleName: scaleName,
      noteFrequency: noteFrequency,
      confidence: _calculateScaleConfidence(noteFrequency),
    );
  }

  static String _determineScaleName(Map<int, int> noteFrequency, int tonic) {
    // 장조 패턴: 1, 3, 5 (도, 미, 솔)
    final majorTriad = [(tonic + 0) % 12, (tonic + 4) % 12, (tonic + 7) % 12];
    // 단조 패턴: 1, b3, 5 (도, 미♭, 솔)
    final minorTriad = [(tonic + 0) % 12, (tonic + 3) % 12, (tonic + 7) % 12];
    
    int majorScore = 0;
    int minorScore = 0;
    
    for (final note in majorTriad) {
      majorScore += noteFrequency[note] ?? 0;
    }
    
    for (final note in minorTriad) {
      minorScore += noteFrequency[note] ?? 0;
    }
    
    return majorScore >= minorScore ? '장조' : '단조';
  }

  static double _calculateScaleConfidence(Map<int, int> noteFrequency) {
    if (noteFrequency.isEmpty) return 0.0;
    
    final total = noteFrequency.values.reduce((a, b) => a + b);
    final maxFreq = noteFrequency.values.reduce((a, b) => a > b ? a : b);
    
    return maxFreq / total;
  }
}

/// 음표 정보 클래스
class NoteInfo {
  final String noteName;
  final int octave;
  final double frequency;
  final int midiNote;
  final int cents;
  final bool isSharp;

  const NoteInfo({
    required this.noteName,
    required this.octave,
    required this.frequency,
    required this.midiNote,
    required this.cents,
    required this.isSharp,
  });

  String get fullNoteName => '$noteName$octave';
  
  String get noteWithCents {
    if (cents == 0) return fullNoteName;
    final sign = cents > 0 ? '+' : '';
    return '$fullNoteName (${sign}${cents}¢)';
  }

  @override
  String toString() => noteWithCents;
}

/// 음표 이벤트 클래스
class NoteEvent {
  final NoteInfo noteInfo;
  final double startTime;
  final double endTime;
  final double duration;

  const NoteEvent({
    required this.noteInfo,
    required this.startTime,
    required this.endTime,
    required this.duration,
  });

  @override
  String toString() {
    return '${noteInfo.fullNoteName} '
           '(${startTime.toStringAsFixed(2)}s - ${endTime.toStringAsFixed(2)}s, '
           '${duration.toStringAsFixed(2)}s)';
  }
}

/// 스케일 분석 결과 클래스
class ScaleAnalysis {
  final String tonicNote;
  final String scaleName;
  final Map<int, int> noteFrequency;
  final double confidence;

  const ScaleAnalysis({
    required this.tonicNote,
    required this.scaleName,
    required this.noteFrequency,
    required this.confidence,
  });

  @override
  String toString() {
    return '$tonicNote $scaleName (신뢰도: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}

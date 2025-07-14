import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import '../services/pitch_analyzer.dart';
import '../utils/note_converter.dart';

/// 음원 분석을 총괄하는 서비스 클래스
class AudioAnalysisService {
  final PitchAnalyzer _pitchAnalyzer = PitchAnalyzer();
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// 오디오 파일에서 피치를 분석하고 계이름으로 변환
  Future<AudioAnalysisResult> analyzeAudioFile(String audioPath) async {
    try {
      // 오디오 파일 로드
      final audioData = await _loadAudioFile(audioPath);
      
      // 피치 분석
      final pitchFrames = await _pitchAnalyzer.analyzePitch(audioData.samples);
      
      // 계이름으로 변환
      final noteEvents = NoteConverter.pitchFramesToNoteEvents(
        pitchFrames.map((frame) => {
          'frequency': frame.frequency,
          'timeStamp': frame.timeStamp,
          'confidence': frame.confidence,
        }).toList(),
      );
      
      // 스케일 분석
      final scaleAnalysis = NoteConverter.analyzeScale(noteEvents);
      
      return AudioAnalysisResult(
        audioPath: audioPath,
        duration: audioData.duration,
        sampleRate: audioData.sampleRate,
        pitchFrames: pitchFrames,
        noteEvents: noteEvents,
        scaleAnalysis: scaleAnalysis,
        analysisTimestamp: DateTime.now(),
      );
      
    } catch (e) {
      throw AudioAnalysisException('음원 분석 중 오류가 발생했습니다: $e');
    }
  }

  /// 특정 시간 구간의 피치를 분석
  Future<List<NoteEvent>> analyzeTimeRange(
    String audioPath, 
    double startTime, 
    double endTime,
  ) async {
    final audioData = await _loadAudioFile(audioPath);
    
    final startSample = (startTime * audioData.sampleRate).round();
    final endSample = (endTime * audioData.sampleRate).round();
    
    if (startSample >= audioData.samples.length || endSample <= startSample) {
      return [];
    }
    
    final segmentSamples = audioData.samples.sublist(
      startSample,
      endSample.clamp(0, audioData.samples.length),
    );
    
    final pitchFrames = await _pitchAnalyzer.analyzePitch(segmentSamples);
    
    // 시간 오프셋 조정
    final adjustedFrames = pitchFrames.map((frame) => PitchFrame(
      timeStamp: frame.timeStamp + startTime,
      frequency: frame.frequency,
      confidence: frame.confidence,
    )).toList();
    
    return NoteConverter.pitchFramesToNoteEvents(
      adjustedFrames.map((frame) => {
        'frequency': frame.frequency,
        'timeStamp': frame.timeStamp,
        'confidence': frame.confidence,
      }).toList(),
    );
  }

  /// 실시간 피치 분석 (마이크 입력용)
  Stream<NoteInfo> analyzeMicrophoneInput() {
    // 실시간 마이크 입력 분석은 별도의 플러그인이 필요
    // 여기서는 기본 구조만 제공
    throw UnimplementedError('실시간 마이크 분석은 추후 구현 예정');
  }

  /// 오디오 파일 로드
  Future<AudioData> _loadAudioFile(String audioPath) async {
    try {
      // Asset에서 오디오 로드
      if (audioPath.startsWith('assets/')) {
        return await _loadAssetAudio(audioPath);
      } 
      // 파일 시스템에서 오디오 로드
      else {
        return await _loadFileAudio(audioPath);
      }
    } catch (e) {
      throw AudioAnalysisException('오디오 파일을 로드할 수 없습니다: $e');
    }
  }

  /// Asset 오디오 로드
  Future<AudioData> _loadAssetAudio(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();
    
    // 실제 구현에서는 오디오 디코딩 라이브러리 필요
    // 예: flutter_ffmpeg, dart_wav, 등
    // 여기서는 시뮬레이션된 데이터 반환
    return _createSimulatedAudioData(bytes.length);
  }

  /// 파일 오디오 로드
  Future<AudioData> _loadFileAudio(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw AudioAnalysisException('파일을 찾을 수 없습니다: $filePath');
    }
    
    final bytes = await file.readAsBytes();
    return _createSimulatedAudioData(bytes.length);
  }

  /// 시뮬레이션된 오디오 데이터 생성 (실제로는 디코딩 필요)
  AudioData _createSimulatedAudioData(int byteLength) {
    // 실제 구현에서는 오디오 디코딩이 필요
    // 여기서는 예시를 위한 시뮬레이션
    const sampleRate = 44100;
    final sampleCount = (byteLength / 4).floor(); // 32-bit float 가정
    final samples = Float32List(sampleCount);
    
    // 테스트용 사인파 생성 (실제로는 디코딩된 데이터 사용)
    for (int i = 0; i < sampleCount; i++) {
      samples[i] = 0.5 * (sin(2 * 3.14159 * 440 * i / sampleRate) as double);
    }
    
    return AudioData(
      samples: samples,
      sampleRate: sampleRate,
      duration: sampleCount / sampleRate,
    );
  }

  /// 리소스 정리
  void dispose() {
    _audioPlayer.dispose();
  }
}

/// 오디오 데이터 클래스
class AudioData {
  final Float32List samples;
  final int sampleRate;
  final double duration;

  const AudioData({
    required this.samples,
    required this.sampleRate,
    required this.duration,
  });
}

/// 음원 분석 결과 클래스
class AudioAnalysisResult {
  final String audioPath;
  final double duration;
  final int sampleRate;
  final List<PitchFrame> pitchFrames;
  final List<NoteEvent> noteEvents;
  final ScaleAnalysis scaleAnalysis;
  final DateTime analysisTimestamp;

  const AudioAnalysisResult({
    required this.audioPath,
    required this.duration,
    required this.sampleRate,
    required this.pitchFrames,
    required this.noteEvents,
    required this.scaleAnalysis,
    required this.analysisTimestamp,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'audioPath': audioPath,
      'duration': duration,
      'sampleRate': sampleRate,
      'analysisTimestamp': analysisTimestamp.toIso8601String(),
      'scaleAnalysis': {
        'tonicNote': scaleAnalysis.tonicNote,
        'scaleName': scaleAnalysis.scaleName,
        'confidence': scaleAnalysis.confidence,
      },
      'noteEvents': noteEvents.map((event) => {
        'noteName': event.noteInfo.fullNoteName,
        'frequency': event.noteInfo.frequency,
        'startTime': event.startTime,
        'endTime': event.endTime,
        'duration': event.duration,
        'midiNote': event.noteInfo.midiNote,
        'cents': event.noteInfo.cents,
      }).toList(),
      'pitchFrames': pitchFrames.map((frame) => {
        'timeStamp': frame.timeStamp,
        'frequency': frame.frequency,
        'confidence': frame.confidence,
      }).toList(),
    };
  }

  @override
  String toString() {
    return '음원 분석 결과\n'
           '파일: $audioPath\n'
           '길이: ${duration.toStringAsFixed(1)}초\n'
           '스케일: $scaleAnalysis\n'
           '음표 수: ${noteEvents.length}개\n'
           '분석 시간: $analysisTimestamp';
  }
}

/// 음원 분석 예외 클래스
class AudioAnalysisException implements Exception {
  final String message;
  
  const AudioAnalysisException(this.message);
  
  @override
  String toString() => 'AudioAnalysisException: $message';
}

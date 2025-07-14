import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:fftea/fftea.dart';

/// 피치 분석을 위한 서비스 클래스
class PitchAnalyzer {
  static const int sampleRate = 44100;
  static const int windowSize = 4096;
  static const int hopSize = 1024;
  static const double minFrequency = 80.0;  // 저음 E2
  static const double maxFrequency = 2000.0;  // 고음 B6

  final FFT _fft;

  PitchAnalyzer() : _fft = FFT(windowSize);

  /// 오디오 샘플에서 피치를 추출합니다
  Future<List<PitchFrame>> analyzePitch(Float32List audioSamples) async {
    final List<PitchFrame> pitchFrames = [];
    
    for (int i = 0; i < audioSamples.length - windowSize; i += hopSize) {
      final window = audioSamples.sublist(i, i + windowSize);
      final timeStamp = i / sampleRate;
      final frequency = _detectPitch(window);
      
      if (frequency > 0) {
        pitchFrames.add(PitchFrame(
          timeStamp: timeStamp,
          frequency: frequency,
          confidence: _calculateConfidence(window, frequency),
        ));
      }
    }
    
    return pitchFrames;
  }

  /// 윈도우에서 피치를 감지합니다 (Autocorrelation 방법)
  double _detectPitch(Float32List window) {
    // 윈도우 함수 적용 (Hamming window)
    final windowed = _applyHammingWindow(window);
    
    // 자기상관함수 계산
    final autocorrelation = _calculateAutocorrelation(windowed);
    
    // 피크 찾기
    final minPeriod = (sampleRate / maxFrequency).round();
    final maxPeriod = (sampleRate / minFrequency).round();
    
    double maxCorrelation = 0.0;
    int bestPeriod = 0;
    
    for (int period = minPeriod; period < maxPeriod && period < autocorrelation.length; period++) {
      if (autocorrelation[period] > maxCorrelation) {
        maxCorrelation = autocorrelation[period];
        bestPeriod = period;
      }
    }
    
    if (bestPeriod > 0 && maxCorrelation > 0.3) {
      // 파라볼릭 보간으로 정확도 향상
      final refinedPeriod = _parabolicInterpolation(autocorrelation, bestPeriod);
      return sampleRate / refinedPeriod;
    }
    
    return 0.0;
  }

  /// Hamming 윈도우 함수 적용
  Float32List _applyHammingWindow(Float32List samples) {
    final windowed = Float32List(samples.length);
    for (int i = 0; i < samples.length; i++) {
      final windowValue = 0.54 - 0.46 * cos(2 * pi * i / (samples.length - 1));
      windowed[i] = samples[i] * windowValue;
    }
    return windowed;
  }

  /// 자기상관함수 계산
  Float32List _calculateAutocorrelation(Float32List samples) {
    final length = samples.length;
    final autocorr = Float32List(length ~/ 2);
    
    for (int lag = 0; lag < autocorr.length; lag++) {
      double sum = 0.0;
      for (int i = 0; i < length - lag; i++) {
        sum += samples[i] * samples[i + lag];
      }
      autocorr[lag] = sum;
    }
    
    // 정규화
    if (autocorr[0] > 0) {
      for (int i = 0; i < autocorr.length; i++) {
        autocorr[i] /= autocorr[0];
      }
    }
    
    return autocorr;
  }

  /// 파라볼릭 보간으로 피크 위치를 정밀하게 계산
  double _parabolicInterpolation(Float32List data, int peakIndex) {
    if (peakIndex <= 0 || peakIndex >= data.length - 1) {
      return peakIndex.toDouble();
    }
    
    final y1 = data[peakIndex - 1];
    final y2 = data[peakIndex];
    final y3 = data[peakIndex + 1];
    
    final a = (y1 - 2 * y2 + y3) / 2;
    final b = (y3 - y1) / 2;
    
    if (a == 0) return peakIndex.toDouble();
    
    final xOffset = -b / (2 * a);
    return peakIndex + xOffset;
  }

  /// 피치 감지의 신뢰도 계산
  double _calculateConfidence(Float32List window, double frequency) {
    if (frequency <= 0) return 0.0;
    
    final period = sampleRate / frequency;
    final autocorr = _calculateAutocorrelation(window);
    final periodIndex = period.round();
    
    if (periodIndex < autocorr.length) {
      return autocorr[periodIndex].clamp(0.0, 1.0);
    }
    
    return 0.0;
  }
}

/// 피치 프레임 데이터 클래스
class PitchFrame {
  final double timeStamp;
  final double frequency;
  final double confidence;

  const PitchFrame({
    required this.timeStamp,
    required this.frequency,
    required this.confidence,
  });

  @override
  String toString() {
    return 'PitchFrame(time: ${timeStamp.toStringAsFixed(3)}s, '
           'freq: ${frequency.toStringAsFixed(1)}Hz, '
           'conf: ${confidence.toStringAsFixed(2)})';
  }
}

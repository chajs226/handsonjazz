import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/audio_player_bloc.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/song.dart';

/// 오선지 형태로 멜로디 라인을 표시하는 위젯 (점으로만 표현)
class StaffNotationWidget extends StatefulWidget {
  final Song song;
  
  const StaffNotationWidget({
    super.key,
    required this.song,
  });

  @override
  State<StaffNotationWidget> createState() => _StaffNotationWidgetState();
}

class _StaffNotationWidgetState extends State<StaffNotationWidget> {
  ScrollController? _scrollController;
  double _currentTime = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildStaffNotation(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.music_note,
            color: Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '오선지 악보',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '${widget.song.title}',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffNotation() {
    if (widget.song.pitchAnalysis == null) {
      return const Center(
        child: Text(
          '피치 분석 데이터가 없습니다.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final melodyLine = widget.song.pitchAnalysis!['melodyLine'] as List<dynamic>? ?? [];
    
    if (melodyLine.isEmpty) {
      return const Center(
        child: Text(
          '멜로디 라인 데이터를 로딩 중...',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return BlocListener<AudioPlayerBloc, AudioPlayerState>(
      listener: (context, state) {
        if (state.audioState.isPlaying) {
          setState(() {
            _currentTime = state.audioState.currentPosition.inMilliseconds / 1000.0;
          });
          _scrollToCurrentPosition();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: CustomPaint(
            size: Size(_calculateStaffWidth(melodyLine), 120),
            painter: StaffNotationPainter(
              melodyLine: melodyLine,
              currentTime: _currentTime,
              song: widget.song,
            ),
          ),
        ),
      ),
    );
  }

  double _calculateStaffWidth(List<dynamic> melodyLine) {
    if (melodyLine.isEmpty) return 400;
    
    final startTime = widget.song.structure.startTimeSeconds.toDouble();
    
    final lastNote = melodyLine.last;
    final lastTime = (lastNote['endTime'] as num).toDouble();
    
    final totalDuration = lastTime - startTime;
    
    // 픽셀당 초 단위로 계산 (1초당 50픽셀)
    const pixelsPerSecond = 50.0;
    return totalDuration * pixelsPerSecond + 100; // 여유 공간 추가
  }

  void _scrollToCurrentPosition() {
    if (_scrollController?.hasClients ?? false) {
      const pixelsPerSecond = 50.0;
      final startTime = widget.song.structure.startTimeSeconds.toDouble();
      
      final timeFromStart = _currentTime - startTime;
      final targetOffset = (timeFromStart * pixelsPerSecond) - (MediaQuery.of(context).size.width / 2);
      final maxOffset = _scrollController!.position.maxScrollExtent;
      final clampedOffset = targetOffset.clamp(0.0, maxOffset);
      
      _scrollController!.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }
}

class StaffNotationPainter extends CustomPainter {
  final List<dynamic> melodyLine;
  final double currentTime;
  final Song song;
  
  static const double staffHeight = 80;
  static const double staffLineSpacing = 10;
  static const int staffLines = 5;
  
  StaffNotationPainter({
    required this.melodyLine,
    required this.currentTime,
    required this.song,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final secondsPerMeasure = song.structure.secondsPerMeasure.toDouble();
    final startTime = song.structure.startTimeSeconds.toDouble();
    
    final lastNote = melodyLine.isNotEmpty ? melodyLine.last : null;
    final lastTime = lastNote != null ? (lastNote['endTime'] as num).toDouble() : startTime + secondsPerMeasure;
    final totalMeasures = ((lastTime - startTime) / secondsPerMeasure).ceil();
    
    _drawStaff(canvas, size, totalMeasures);
    _drawMeasureLines(canvas, size, totalMeasures, secondsPerMeasure, startTime);
    _drawMelodyDots(canvas, size, secondsPerMeasure, startTime);
    _drawPlaybackPosition(canvas, size, secondsPerMeasure, startTime);
  }

  void _drawStaff(Canvas canvas, Size size, int totalMeasures) {
    final staffPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.0;
    
    final staffTop = 20.0;
    
    for (int i = 0; i < staffLines; i++) {
      final y = staffTop + (i * staffLineSpacing);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        staffPaint,
      );
    }
  }

  void _drawMeasureLines(Canvas canvas, Size size, int totalMeasures, double secondsPerMeasure, double startTime) {
    final measurePaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 2.0;
    
    final staffTop = 20.0;
    const pixelsPerSecond = 50.0;
    
    // 코드 진행에 기반한 실제 마디선 그리기
    final chordProgression = song.chordProgression;
    final chordTimes = chordProgression.keys
        .map((key) => double.tryParse(key) ?? 0.0)
        .where((time) => time >= startTime)
        .toList();
    chordTimes.sort();
    
    // 시작점에 선 그리기
    canvas.drawLine(
      Offset(0, staffTop),
      Offset(0, staffTop + staffHeight),
      measurePaint,
    );
    
    for (int i = 0; i < chordTimes.length; i++) {
      final chordTime = chordTimes[i];
      final timeFromStart = chordTime - startTime;
      final x = timeFromStart * pixelsPerSecond;
      
      if (x > 0 && x < size.width) {
        canvas.drawLine(
          Offset(x, staffTop),
          Offset(x, staffTop + staffHeight),
          measurePaint,
        );
        
        // 코드 이름 표시
        final chordKey = chordTime.toString();
        final chord = chordProgression[chordKey] as String? ?? 
                     chordProgression[chordTime.toStringAsFixed(1)] as String?;
        if (chord != null) {
          final chordPainter = TextPainter(
            text: TextSpan(
              text: chord,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          chordPainter.layout();
          chordPainter.paint(
            canvas,
            Offset(x + 5, staffTop - 20),
          );
        }
        
        // 마디 번호 표시 (4마디마다)
        if (i % 4 == 0) {
          final measureNumber = (i ~/ 4) + 1;
          final textPainter = TextPainter(
            text: TextSpan(
              text: '$measureNumber',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(x + 5, staffTop + staffHeight + 5),
          );
        }
      }
    }
  }

  void _drawMelodyDots(Canvas canvas, Size size, double secondsPerMeasure, double startTime) {
    const pixelsPerSecond = 50.0;
    
    for (final note in melodyLine) {
      final noteStartTime = (note['startTime'] as num).toDouble();
      final noteEndTime = (note['endTime'] as num).toDouble();
      final noteName = note['noteName'] as String;
      final midiNote = (note['midiNote'] as num).toInt();
      final confidence = (note['confidence'] as num).toDouble();
      
      // 실제 시간에 따른 정확한 위치 계산
      final timeFromStart = noteStartTime - startTime;
      final x = timeFromStart * pixelsPerSecond;
      
      // 음표의 길이를 시각적으로 표현
      final noteDuration = noteEndTime - noteStartTime;
      final noteWidth = noteDuration * pixelsPerSecond;
      
      final y = _calculateNoteY(midiNote);
      
      final isCurrentNote = currentTime >= noteStartTime && currentTime <= noteEndTime;
      final isPastNote = currentTime > noteEndTime;
      
      Color dotColor;
      if (isCurrentNote) {
        dotColor = AppTheme.accentColor;
      } else if (isPastNote) {
        dotColor = Colors.grey.shade500;
      } else {
        dotColor = Colors.white;
      }
      
      final opacity = (confidence * 0.7 + 0.3).clamp(0.3, 1.0);
      
      // 음표 길이에 따라 점의 크기 조정 (최소 2.0, 최대 6.0)
      final dotRadius = (noteDuration * 3.0).clamp(2.0, 6.0);
      
      final dotPaint = Paint()
        ..color = dotColor.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
      
      // 긴 음표의 경우 지속선을 그려서 표현
      if (noteWidth > 20) {
        final linePaint = Paint()
          ..color = dotColor.withOpacity(opacity * 0.5)
          ..strokeWidth = 2.0;
        
        canvas.drawLine(
          Offset(x + dotRadius, y),
          Offset(x + noteWidth - dotRadius, y),
          linePaint,
        );
      }
      
      if (isCurrentNote) {
        final borderPaint = Paint()
          ..color = AppTheme.accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(Offset(x, y), dotRadius + 1, borderPaint);
        
        final textPainter = TextPainter(
          text: TextSpan(
            text: noteName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y - 20),
        );
      }
    }
  }

  double _calculateNoteY(int midiNote) {
    final staffTop = 20.0;
    // 한 옥타브 올려서 표시 (midiNote + 12)
    final adjustedMidiNote = midiNote + 12;
    // C5 (72)를 기준으로 오선지 중앙에 배치
    final c5Position = staffTop + (staffHeight / 2);
    final semitoneOffset = (adjustedMidiNote - 72) * (staffLineSpacing / 4);
    return c5Position - semitoneOffset;
  }

  void _drawPlaybackPosition(Canvas canvas, Size size, double secondsPerMeasure, double startTime) {
    if (currentTime < startTime) return;
    
    const pixelsPerSecond = 50.0;
    final timeFromStart = currentTime - startTime;
    final x = timeFromStart * pixelsPerSecond;
    
    if (x < 0 || x > size.width) return;
    
    final staffTop = 20.0;
    
    final playbackPaint = Paint()
      ..color = AppTheme.accentColor
      ..strokeWidth = 2.0;
    
    canvas.drawLine(
      Offset(x, staffTop - 10),
      Offset(x, staffTop + staffHeight + 10),
      playbackPaint,
    );
    
    final arrowPath = Path();
    arrowPath.moveTo(x, staffTop - 10);
    arrowPath.lineTo(x - 4, staffTop - 18);
    arrowPath.lineTo(x + 4, staffTop - 18);
    arrowPath.close();
    
    canvas.drawPath(arrowPath, Paint()..color = AppTheme.accentColor);
  }

  @override
  bool shouldRepaint(covariant StaffNotationPainter oldDelegate) {
    return oldDelegate.currentTime != currentTime ||
           oldDelegate.melodyLine != melodyLine;
  }
}

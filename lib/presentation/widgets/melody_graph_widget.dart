import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/audio_player_bloc.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/song.dart';

/// 멜로디 라인을 그래프로 표시하는 위젯
class MelodyGraphWidget extends StatefulWidget {
  final Song song;
  
  const MelodyGraphWidget({
    super.key,
    required this.song,
  });

  @override
  State<MelodyGraphWidget> createState() => _MelodyGraphWidgetState();
}

class _MelodyGraphWidgetState extends State<MelodyGraphWidget> {
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
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildMelodyGraph(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(8),
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
            Icons.show_chart,
            color: Colors.white70,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '멜로디 그래프',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '${widget.song.title}',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMelodyGraph() {
    if (widget.song.pitchAnalysis == null) {
      return const Center(
        child: Text(
          '멜로디 분석 데이터가 없습니다.',
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
            size: Size(_calculateGraphWidth(melodyLine), 80),
            painter: MelodyGraphPainter(
              melodyLine: melodyLine,
              currentTime: _currentTime,
              song: widget.song,
            ),
          ),
        ),
      ),
    );
  }

  double _calculateGraphWidth(List<dynamic> melodyLine) {
    if (melodyLine.isEmpty) return 400;
    
    final startTime = widget.song.structure.startTimeSeconds.toDouble();
    final lastNote = melodyLine.last;
    final lastTime = (lastNote['endTime'] as num).toDouble();
    final totalDuration = lastTime - startTime;
    
    // 1초당 50픽셀
    const pixelsPerSecond = 50.0;
    return totalDuration * pixelsPerSecond + 100;
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

class MelodyGraphPainter extends CustomPainter {
  final List<dynamic> melodyLine;
  final double currentTime;
  final Song song;
  
  MelodyGraphPainter({
    required this.melodyLine,
    required this.currentTime,
    required this.song,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final startTime = song.structure.startTimeSeconds.toDouble();
    
    _drawGrid(canvas, size);
    _drawMelodyLine(canvas, size, startTime);
    _drawCurrentPosition(canvas, size, startTime);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 0.5;
    
    // 가로선 (음높이 기준선)
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  void _drawMelodyLine(Canvas canvas, Size size, double startTime) {
    if (melodyLine.isEmpty) return;
    
    const pixelsPerSecond = 50.0;
    final points = <Offset>[];
    
    // MIDI 노트 범위 계산
    final midiNotes = melodyLine.map((note) => (note['midiNote'] as num).toInt()).toList();
    final minMidi = midiNotes.reduce((a, b) => a < b ? a : b);
    final maxMidi = midiNotes.reduce((a, b) => a > b ? a : b);
    final midiRange = maxMidi - minMidi;
    
    // 멜로디 포인트 생성
    for (final note in melodyLine) {
      final noteStartTime = (note['startTime'] as num).toDouble();
      final noteEndTime = (note['endTime'] as num).toDouble();
      final midiNote = (note['midiNote'] as num).toInt();
      
      final timeFromStart = noteStartTime - startTime;
      final x = timeFromStart * pixelsPerSecond;
      
      // MIDI 노트를 Y 좌표로 변환 (높은 음이 위쪽)
      final normalizedMidi = midiRange > 0 ? (midiNote - minMidi) / midiRange : 0.5;
      final y = size.height - (normalizedMidi * size.height);
      
      points.add(Offset(x, y));
      
      // 긴 음표의 경우 끝점도 추가
      if (noteEndTime - noteStartTime > 1.0) {
        final endTimeFromStart = noteEndTime - startTime;
        final endX = endTimeFromStart * pixelsPerSecond;
        points.add(Offset(endX, y));
      }
    }
    
    // 멜로디 라인 그리기
    if (points.length > 1) {
      final linePaint = Paint()
        ..color = AppTheme.accentColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      
      canvas.drawPath(path, linePaint);
    }
    
    // 멜로디 포인트 그리기
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final note = melodyLine[i % melodyLine.length];
      final noteStartTime = (note['startTime'] as num).toDouble();
      final noteEndTime = (note['endTime'] as num).toDouble();
      final isCurrentNote = currentTime >= noteStartTime && currentTime <= noteEndTime;
      final isPastNote = currentTime > noteEndTime;
      
      Color pointColor;
      double pointRadius;
      
      if (isCurrentNote) {
        pointColor = AppTheme.accentColor;
        pointRadius = 4.0;
      } else if (isPastNote) {
        pointColor = Colors.grey.shade500;
        pointRadius = 3.0;
      } else {
        pointColor = Colors.white;
        pointRadius = 3.0;
      }
      
      final pointPaint = Paint()
        ..color = pointColor
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(point, pointRadius, pointPaint);
      
      // 현재 재생 중인 음표에 테두리 추가
      if (isCurrentNote) {
        final borderPaint = Paint()
          ..color = AppTheme.accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(point, pointRadius + 1, borderPaint);
        
        // 음표 이름 표시
        final noteName = note['noteName'] as String;
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
          Offset(point.dx - textPainter.width / 2, point.dy - 20),
        );
      }
    }
  }

  void _drawCurrentPosition(Canvas canvas, Size size, double startTime) {
    if (currentTime < startTime) return;
    
    const pixelsPerSecond = 50.0;
    final timeFromStart = currentTime - startTime;
    final x = timeFromStart * pixelsPerSecond;
    
    if (x >= 0 && x <= size.width) {
      final positionPaint = Paint()
        ..color = AppTheme.accentColor
        ..strokeWidth = 2.0;
      
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        positionPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MelodyGraphPainter oldDelegate) {
    return oldDelegate.currentTime != currentTime ||
           oldDelegate.melodyLine != melodyLine;
  }
}

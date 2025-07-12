import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/audio_player_bloc.dart';
import '../../core/services/timing_service.dart';
import '../../app/theme/app_theme.dart';

class ChordTimelineWidget extends StatelessWidget {
  const ChordTimelineWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, state) {
        if (state.currentSong == null) {
          return const Center(
            child: Text(
              'No song loaded',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final timingService = TimingService();
        final chordTimings = timingService.getChordTimings(state.currentSong!);
        final currentPosition = state.audioState.currentPosition;
        final totalDuration = state.audioState.totalDuration;

        return Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current: ${state.currentChord ?? "—"}',
                      style: const TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_formatDuration(currentPosition)} / ${_formatDuration(totalDuration)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: CustomPaint(
                    painter: ChordTimelinePainter(
                      chordTimings: chordTimings,
                      currentPosition: currentPosition,
                      totalDuration: totalDuration,
                    ),
                    child: GestureDetector(
                      onTapDown: (details) {
                        _onTimelineClick(context, details, totalDuration);
                      },
                      child: Container(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onTimelineClick(BuildContext context, TapDownDetails details, Duration totalDuration) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final timelineWidth = renderBox.size.width - 16; // Subtract margin
    final clickRatio = (localPosition.dx - 8) / timelineWidth; // Subtract left margin
    
    if (clickRatio >= 0 && clickRatio <= 1) {
      final seekPosition = Duration(
        milliseconds: (totalDuration.inMilliseconds * clickRatio).round(),
      );
      context.read<AudioPlayerBloc>().add(SeekAudio(seekPosition));
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class ChordTimelinePainter extends CustomPainter {
  final List<ChordTiming> chordTimings;
  final Duration currentPosition;
  final Duration totalDuration;

  ChordTimelinePainter({
    required this.chordTimings,
    required this.currentPosition,
    required this.totalDuration,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const double timelineHeight = 4;
    final double timelineY = size.height / 2 - timelineHeight / 2;

    // Draw background timeline
    paint.color = Colors.grey.shade700;
    canvas.drawRRect(
      RRect.fromLTRBR(0, timelineY, size.width, timelineY + timelineHeight, 
                      const Radius.circular(2)),
      paint,
    );

    if (totalDuration.inMilliseconds > 0) {
      // Draw progress
      final progressWidth = (currentPosition.inMilliseconds / totalDuration.inMilliseconds) * size.width;
      paint.color = AppTheme.secondaryColor;
      canvas.drawRRect(
        RRect.fromLTRBR(0, timelineY, progressWidth, timelineY + timelineHeight, 
                        const Radius.circular(2)),
        paint,
      );

      // Draw chord markers and labels
      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      
      for (final chordTiming in chordTimings) {
        final markerX = (chordTiming.time.inMilliseconds / totalDuration.inMilliseconds) * size.width;
        
        // Draw marker line
        paint.color = AppTheme.accentColor;
        paint.strokeWidth = 2.0;
        canvas.drawLine(
          Offset(markerX, 0.0),
          Offset(markerX, size.height),
          paint,
        );

        // Draw chord label
        textPainter.text = TextSpan(
          text: chordTiming.chord,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();

        final textX = markerX - textPainter.width / 2;
        final textY = 2.0;
        
        // Draw background for text
        paint.color = AppTheme.primaryColor.withValues(alpha: 0.8);
        paint.style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromLTRBR(
            textX - 2.0, textY - 1.0, 
            textX + textPainter.width + 2.0, textY + textPainter.height + 1.0,
            const Radius.circular(2.0)
          ),
          paint,
        );

        textPainter.paint(canvas, Offset(textX, textY));
      }

      // Draw current position indicator
      final currentX = (currentPosition.inMilliseconds.toDouble() / totalDuration.inMilliseconds.toDouble()) * size.width;
      paint.color = Colors.white;
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(currentX, timelineY + timelineHeight / 2),
        6.0,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ChordTimelinePainter oldDelegate) {
    return oldDelegate.currentPosition != currentPosition ||
           oldDelegate.totalDuration != totalDuration ||
           oldDelegate.chordTimings.length != chordTimings.length;
  }
}

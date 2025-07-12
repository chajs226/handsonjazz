import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/audio_player_bloc.dart';
import '../../core/services/timing_service.dart';
import '../../app/theme/app_theme.dart';

class ChordTimelineWidget extends StatefulWidget {
  const ChordTimelineWidget({Key? key}) : super(key: key);

  @override
  State<ChordTimelineWidget> createState() => _ChordTimelineWidgetState();
}

class _ChordTimelineWidgetState extends State<ChordTimelineWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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

        // Convert chord timings to measure-based structure
        final chordMeasures = _buildChordMeasures(chordTimings, currentPosition, state.currentSong!);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with current chord and time
              Row(
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
              const SizedBox(height: 16),
              // iRealPro style chord chart (4 measures per line)
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: _buildChordChart(context, chordMeasures),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _getCurrentDisplayMeasure(Duration currentPosition, dynamic structure) {
    final startTime = (structure.startTimeSeconds as num).toInt();
    final secondsPerMeasure = (structure.secondsPerMeasure as num).toInt();
    final measuresPerChorus = (structure.measuresPerChorus as num).toInt();
    
    if (currentPosition.inSeconds < startTime) return 0;
    
    final totalMeasuresPassed = ((currentPosition.inSeconds - startTime) / secondsPerMeasure).floor();
    
    // For 2nd chorus and beyond, show as if it's the first chorus (looping back)
    return (totalMeasuresPassed % measuresPerChorus) + 1;
  }

  List<ChordMeasure> _buildChordMeasures(List<ChordTiming> chordTimings, Duration currentPosition, dynamic song) {
    List<ChordMeasure> measures = [];
    final structure = song.structure;
    
    // Create all 32 measures of the first chorus pattern
    for (int measureNum = 1; measureNum <= (structure.measuresPerChorus as num).toInt(); measureNum++) {
      final timing = _findTimingForMeasure(chordTimings, measureNum, structure);
      final isCurrentMeasure = _isCurrentDisplayMeasure(measureNum, currentPosition, structure);
      
      measures.add(ChordMeasure(
        measureNumber: measureNum,
        chord: timing?.chord ?? "—",
        isCurrentMeasure: isCurrentMeasure,
        timing: timing,
      ));
    }
    
    return measures;
  }

  ChordTiming? _findTimingForMeasure(List<ChordTiming> chordTimings, int measureNumber, dynamic structure) {
    final startTime = (structure.startTimeSeconds as num).toInt();
    final secondsPerMeasure = (structure.secondsPerMeasure as num).toInt();
    
    final targetTime = startTime + (measureNumber - 1) * secondsPerMeasure;
    
    // Find the timing that matches this measure's time
    for (final timing in chordTimings) {
      if (timing.time.inSeconds == targetTime) {
        return timing;
      }
    }
    
    return null;
  }

  bool _isCurrentDisplayMeasure(int measureNumber, Duration currentPosition, dynamic structure) {
    final currentDisplayMeasure = _getCurrentDisplayMeasure(currentPosition, structure);
    return measureNumber == currentDisplayMeasure;
  }

  Widget _buildChordChart(BuildContext context, List<ChordMeasure> measures) {
    List<Widget> lines = [];
    
    // Group measures into lines of 4
    for (int i = 0; i < measures.length; i += 4) {
      final lineNumber = (i / 4).floor() + 1;
      final endIndex = (i + 4 > measures.length) ? measures.length : i + 4;
      final lineMeasures = measures.sublist(i, endIndex);
      
      lines.add(_buildChordLine(context, lineNumber, lineMeasures));
      lines.add(const SizedBox(height: 8));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines,
    );
  }

  Widget _buildChordLine(BuildContext context, int lineNumber, List<ChordMeasure> measures) {
    return Container(
      height: 50, // Increased height for better text visibility
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade600, width: 1),
      ),
      child: Row(
        children: [
          // Line number
          Container(
            width: 25,
            alignment: Alignment.center,
            child: Text(
              '$lineNumber',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Measures
          Expanded(
            child: Row(
              children: measures.map((measure) => 
                Expanded(child: _buildMeasureBox(context, measure))
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasureBox(BuildContext context, ChordMeasure measure) {
    return GestureDetector(
      onTap: () {
        if (measure.timing != null) {
          // Seek to this measure's time
          context.read<AudioPlayerBloc>().add(SeekAudio(measure.timing!.time));
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3), // Reduced padding
        decoration: BoxDecoration(
          color: measure.isCurrentMeasure 
              ? AppTheme.accentColor.withValues(alpha: 0.9)
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: measure.isCurrentMeasure 
                ? AppTheme.accentColor 
                : Colors.grey.shade600,
            width: measure.isCurrentMeasure ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            measure.chord,
            style: TextStyle(
              color: measure.isCurrentMeasure ? Colors.black : Colors.white,
              fontSize: 13, // Increased font size for better visibility
              fontWeight: measure.isCurrentMeasure ? FontWeight.bold : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2, // Allow chord names to wrap to 2 lines if needed
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// Data model for chord measures
class ChordMeasure {
  final int measureNumber;
  final String chord;
  final bool isCurrentMeasure;
  final ChordTiming? timing;

  ChordMeasure({
    required this.measureNumber,
    required this.chord,
    required this.isCurrentMeasure,
    this.timing,
  });
}

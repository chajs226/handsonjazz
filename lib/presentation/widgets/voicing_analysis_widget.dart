import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/piano_roll_cubit.dart';
import '../../app/theme/app_theme.dart';

class VoicingAnalysisWidget extends StatelessWidget {
  const VoicingAnalysisWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PianoRollCubit, PianoRollState>(
      builder: (context, state) {
        final voicing = state.currentVoicing;
        
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
              const Text(
                'Voicing Analysis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (voicing != null) ...[
                _buildChordInfo(voicing.chordSymbol),
                const SizedBox(height: 12),
                _buildHandInfo('Left Hand', voicing.leftHand, AppTheme.leftHandColor),
                const SizedBox(height: 8),
                _buildHandInfo('Right Hand', voicing.rightHand, AppTheme.rightHandColor),
                const SizedBox(height: 12),
                _buildAnalysis(voicing.analysis),
              ] else ...[
                const Center(
                  child: Text(
                    'No voicing data available',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildChordInfo(String chordSymbol) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.accentColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.music_note,
            color: AppTheme.accentColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            chordSymbol,
            style: const TextStyle(
              color: AppTheme.accentColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandInfo(String handName, List<int> notes, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              handName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: notes.map((note) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Text(
                _getNoteNameFromMidi(note),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAnalysis(String analysis) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade600),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppTheme.secondaryColor,
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'Analysis',
                style: TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            analysis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _getNoteNameFromMidi(int midiNote) {
    const List<String> noteNames = [
      'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
    ];
    final int noteInOctave = (midiNote - 12) % 12;
    final int octave = ((midiNote - 12) / 12).floor();
    return '${noteNames[noteInOctave]}$octave';
  }
}

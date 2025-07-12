import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/piano_roll_cubit.dart';
import '../../app/theme/app_theme.dart';

class PianoRollWidget extends StatelessWidget {
  const PianoRollWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PianoRollCubit, PianoRollState>(
      builder: (context, state) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  state.currentVoicing?.chordSymbol ?? 'No chord',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,                child: SizedBox(
                  width: 1200, // Wide enough to show all keys
                  child: CustomPaint(
                    painter: PianoRollPainter(
                      activeNotes: state.activeNotes,
                      leftHandNotes: state.currentVoicing?.leftHand ?? [],
                      rightHandNotes: state.currentVoicing?.rightHand ?? [],
                    ),
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
}

class PianoRollPainter extends CustomPainter {
  final List<int> activeNotes;
  final List<int> leftHandNotes;
  final List<int> rightHandNotes;

  PianoRollPainter({
    required this.activeNotes,
    required this.leftHandNotes,
    required this.rightHandNotes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const int totalKeys = 88; // Standard piano keys
    const int startingMidiNote = 21; // A0
    final double keyWidth = size.width / totalKeys;
    final double keyHeight = size.height;

    // Draw piano keys
    for (int i = 0; i < totalKeys; i++) {
      final int midiNote = startingMidiNote + i;
      final bool isBlackKey = _isBlackKey(midiNote);
      final double x = i * keyWidth;

      if (!isBlackKey) {
        // White key
        paint.color = _getKeyColor(midiNote);
        canvas.drawRect(
          Rect.fromLTWH(x, 0, keyWidth - 1, keyHeight),
          paint,
        );

        // Key border
        paint.color = Colors.grey.shade600;
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 1;
        canvas.drawRect(
          Rect.fromLTWH(x, 0, keyWidth - 1, keyHeight),
          paint,
        );
        paint.style = PaintingStyle.fill;
      }
    }

    // Draw black keys on top
    for (int i = 0; i < totalKeys; i++) {
      final int midiNote = startingMidiNote + i;
      final bool isBlackKey = _isBlackKey(midiNote);
      final double x = i * keyWidth;

      if (isBlackKey) {
        paint.color = _getKeyColor(midiNote);
        canvas.drawRect(
          Rect.fromLTWH(x - keyWidth * 0.3, 0, keyWidth * 0.6, keyHeight * 0.6),
          paint,
        );
      }
    }

    // Draw note labels for active keys
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final note in activeNotes) {
      if (note >= startingMidiNote && note < startingMidiNote + totalKeys) {
        final keyIndex = note - startingMidiNote;
        final x = keyIndex * keyWidth;
        final noteName = _getNoteNameFromMidi(note);

        textPainter.text = TextSpan(
          text: noteName,
          style: TextStyle(
            color: _isBlackKey(note) ? Colors.white : Colors.black,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();

        final textX = x + keyWidth / 2 - textPainter.width / 2;
        final textY = keyHeight - 20;
        textPainter.paint(canvas, Offset(textX, textY));
      }
    }
  }

  Color _getKeyColor(int midiNote) {
    if (leftHandNotes.contains(midiNote)) {
      return AppTheme.leftHandColor;
    } else if (rightHandNotes.contains(midiNote)) {
      return AppTheme.rightHandColor;
    } else if (activeNotes.contains(midiNote)) {
      return AppTheme.activeKeyColor;
    } else if (_isBlackKey(midiNote)) {
      return AppTheme.blackKeyColor;
    } else {
      return AppTheme.whiteKeyColor;
    }
  }

  bool _isBlackKey(int midiNote) {
    final int noteInOctave = (midiNote - 21) % 12;
    return [1, 3, 6, 8, 10].contains(noteInOctave);
  }

  String _getNoteNameFromMidi(int midiNote) {
    const List<String> noteNames = [
      'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
    ];
    final int noteInOctave = (midiNote - 12) % 12;
    final int octave = ((midiNote - 12) / 12).floor();
    return '${noteNames[noteInOctave]}$octave';
  }

  @override
  bool shouldRepaint(PianoRollPainter oldDelegate) {
    return oldDelegate.activeNotes != activeNotes ||
           oldDelegate.leftHandNotes != leftHandNotes ||
           oldDelegate.rightHandNotes != rightHandNotes;
  }
}

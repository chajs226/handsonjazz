import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/piano_roll_cubit.dart';
import '../blocs/audio_player_bloc.dart';
import '../../app/theme/app_theme.dart';

class PianoRollWidget extends StatelessWidget {
  const PianoRollWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<AudioPlayerBloc, AudioPlayerState>(
      listener: (context, audioState) {
        // 오디오 상태 변화 시 piano roll 업데이트는 이미 TimingService를 통해 처리됨
      },
      child: BlocBuilder<PianoRollCubit, PianoRollState>(
        builder: (context, state) {
          return Container(
            height: 150, // Reduced height from 200 to 150
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade700),
            ),
            child: Column(
              children: [
                Container(
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
                    scrollDirection: Axis.horizontal,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // 부모 위젯의 너비에 맞춰서 피아노 건반 크기 조정
                        return SizedBox(
                          width: MediaQuery.of(context).size.width - 32, // 패딩 고려
                          child: CustomPaint(
                            painter: PianoRollPainter(
                              activeNotes: state.activeNotes,
                              leftHandNotes: state.currentVoicing?.leftHand ?? [],
                              rightHandNotes: state.currentVoicing?.rightHand ?? [],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
    // 5옥타브: C3(48) ~ B7(95) = 48개 키 (총 60개 세미톤)
    const int totalSemitones = 60; // 5 octaves * 12 semitones
    const int startingMidiNote = 48; // C3
    // 5옥타브 = 35개 흰 건반 (7 * 5)
    const int totalWhiteKeys = 35; 
    final double whiteKeyWidth = size.width / totalWhiteKeys;
    final double keyHeight = size.height;

    // Draw white keys first
    for (int i = 0; i < totalSemitones; i++) {
      final int midiNote = startingMidiNote + i;
      final bool isBlackKey = _isBlackKey(midiNote);
      
      if (!isBlackKey) {
        final double x = _getWhiteKeyPosition(midiNote, whiteKeyWidth);
        
        // White key
        paint.color = _getKeyColor(midiNote);
        canvas.drawRect(
          Rect.fromLTWH(x, 0, whiteKeyWidth, keyHeight),
          paint,
        );

        // Key border
        paint.color = Colors.grey.shade600;
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 1;
        canvas.drawRect(
          Rect.fromLTWH(x, 0, whiteKeyWidth, keyHeight),
          paint,
        );
        paint.style = PaintingStyle.fill;
      }
    }

    // Draw black keys on top with proper positioning
    for (int i = 0; i < totalSemitones; i++) {
      final int midiNote = startingMidiNote + i;
      if (_isBlackKey(midiNote)) {
        final double x = _getBlackKeyPosition(midiNote, whiteKeyWidth);
        
        paint.color = _getKeyColor(midiNote);
        canvas.drawRect(
          Rect.fromLTWH(x, 0, whiteKeyWidth * 0.6, keyHeight * 0.6),
          paint,
        );
        
        // Black key border
        paint.color = Colors.grey.shade800;
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 1;
        canvas.drawRect(
          Rect.fromLTWH(x, 0, whiteKeyWidth * 0.6, keyHeight * 0.6),
          paint,
        );
        paint.style = PaintingStyle.fill;
      }
    }

    // Draw note labels for active keys
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final note in activeNotes) {
      if (note >= startingMidiNote && note < startingMidiNote + totalSemitones) {
        final double x;
        if (_isBlackKey(note)) {
          x = _getBlackKeyPosition(note, whiteKeyWidth);
        } else {
          x = _getWhiteKeyPosition(note, whiteKeyWidth);
        }
        
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

        final textX = x + (_isBlackKey(note) ? whiteKeyWidth * 0.3 : whiteKeyWidth / 2) - textPainter.width / 2;
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
    final int noteInOctave = midiNote % 12;
    return [1, 3, 6, 8, 10].contains(noteInOctave); // C#, D#, F#, G#, A#
  }

  double _getWhiteKeyPosition(int midiNote, double whiteKeyWidth) {
    // Calculate position for white keys only
    final int whiteKeyIndex = _getWhiteKeyIndex(midiNote);
    return whiteKeyIndex * whiteKeyWidth;
  }

  double _getBlackKeyPosition(int midiNote, double whiteKeyWidth) {
    // Calculate position for black keys between white keys
    final int noteInOctave = midiNote % 12;
    final int octave = (midiNote - 48) ~/ 12; // Starting from C3 (48)
    final double octaveStart = octave * 7 * whiteKeyWidth; // 7 white keys per octave
    
    switch (noteInOctave) {
      case 1: // C#
        return octaveStart + whiteKeyWidth * 0.7;
      case 3: // D#
        return octaveStart + whiteKeyWidth * 1.7;
      case 6: // F#
        return octaveStart + whiteKeyWidth * 3.7;
      case 8: // G#
        return octaveStart + whiteKeyWidth * 4.7;
      case 10: // A#
        return octaveStart + whiteKeyWidth * 5.7;
      default:
        return 0; // Should not happen for black keys
    }
  }

  int _getWhiteKeyIndex(int midiNote) {
    // Calculate how many white keys come before this note from C3 (48)
    const int startNote = 48; // C3
    final int noteOffset = midiNote - startNote;
    final int octave = noteOffset ~/ 12;
    final int noteInOctave = noteOffset % 12;
    
    // White keys in an octave: C, D, E, F, G, A, B (7 keys)
    const List<int> whiteKeyOffsets = [0, 2, 4, 5, 7, 9, 11];
    int whiteKeysInThisOctave = 0;
    
    for (int offset in whiteKeyOffsets) {
      if (offset <= noteInOctave) {
        whiteKeysInThisOctave++;
      } else {
        break;
      }
    }
    
    return octave * 7 + whiteKeysInThisOctave - 1;
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

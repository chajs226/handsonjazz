import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/audio_player_bloc.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/song.dart';

/// 멜로디 라인을 계이름으로 표시하는 위젯
class MelodyLineWidget extends StatefulWidget {
  final Song song;
  
  const MelodyLineWidget({
    super.key,
    required this.song,
  });

  @override
  State<MelodyLineWidget> createState() => _MelodyLineWidgetState();
}

class _MelodyLineWidgetState extends State<MelodyLineWidget> {
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
            child: _buildMelodyTimeline(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.music_note,
            color: AppTheme.accentColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            '멜로디 라인 (계이름)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '오른손 솔로 연습',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMelodyTimeline() {
    if (widget.song.pitchAnalysis == null) {
      return const Center(
        child: Text(
          '멜로디 데이터가 없습니다',
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
          child: SizedBox(
            height: 80,
            child: Row(
              children: _buildMeasureBasedMelody(melodyLine),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMeasureBasedMelody(List<dynamic> melodyLine) {
    final List<Widget> measureWidgets = [];
    final secondsPerMeasure = widget.song.structure['secondsPerMeasure'] as double? ?? 1.625;
    final startTime = widget.song.structure['startTimeSeconds'] as double? ?? 13.0;
    final chordProgression = widget.song.chordProgression;
    
    // 마디별로 멜로디 그룹화
    final Map<int, List<dynamic>> measureGroups = {};
    final Map<int, String?> measureChords = {};
    
    for (final note in melodyLine) {
      final noteStartTime = (note['startTime'] as num).toDouble();
      final measureNumber = ((noteStartTime - startTime) / secondsPerMeasure).floor();
      
      if (!measureGroups.containsKey(measureNumber)) {
        measureGroups[measureNumber] = [];
      }
      measureGroups[measureNumber]!.add(note);
      
      // 해당 마디의 코드 찾기
      if (!measureChords.containsKey(measureNumber)) {
        final measureStartTime = startTime + (measureNumber * secondsPerMeasure);
        measureChords[measureNumber] = _getChordAtTime(measureStartTime, chordProgression);
      }
    }
    
    // 마디 순서대로 정렬
    final sortedMeasures = measureGroups.keys.toList()..sort();
    
    for (int i = 0; i < sortedMeasures.length; i++) {
      final measureNumber = sortedMeasures[i];
      final measureNotes = measureGroups[measureNumber]!;
      final measureChord = measureChords[measureNumber];
      
      measureWidgets.add(
        _buildMeasureWidget(
          measureNumber: measureNumber + 1, // 1부터 시작
          notes: measureNotes,
          chord: measureChord,
          secondsPerMeasure: secondsPerMeasure,
        ),
      );
      
      // 마디 사이 구분선
      if (i < sortedMeasures.length - 1) {
        measureWidgets.add(_buildMeasureDivider());
      }
    }
    
    return measureWidgets;
  }

  String? _getChordAtTime(double time, Map<String, dynamic> chordProgression) {
    String? currentChord;
    double closestTime = double.negativeInfinity;
    
    for (final entry in chordProgression.entries) {
      final chordTime = double.tryParse(entry.key) ?? 0.0;
      if (chordTime <= time && chordTime > closestTime) {
        closestTime = chordTime;
        currentChord = entry.value as String;
      }
    }
    
    return currentChord;
  }

  Widget _buildMeasureWidget({
    required int measureNumber,
    required List<dynamic> notes,
    required String? chord,
    required double secondsPerMeasure,
  }) {
    final measureStartTime = widget.song.structure['startTimeSeconds'] as double? ?? 13.0;
    final actualMeasureStartTime = measureStartTime + ((measureNumber - 1) * secondsPerMeasure);
    final actualMeasureEndTime = actualMeasureStartTime + secondsPerMeasure;
    
    final isCurrentMeasure = _currentTime >= actualMeasureStartTime && _currentTime < actualMeasureEndTime;
    
    return Container(
      width: 180, // 마디 너비 축소
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isCurrentMeasure 
            ? AppTheme.accentColor.withOpacity(0.1)
            : AppTheme.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCurrentMeasure 
              ? AppTheme.accentColor 
              : Colors.grey.shade600,
          width: isCurrentMeasure ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // 마디 헤더 (마디 번호 + 코드) - 높이 축소
          Container(
            height: 20, // 고정 높이
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isCurrentMeasure 
                  ? AppTheme.accentColor.withOpacity(0.2)
                  : Colors.grey.shade700.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${measureNumber}마디',
                  style: TextStyle(
                    color: isCurrentMeasure ? AppTheme.accentColor : Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (chord != null)
                  Text(
                    chord,
                    style: TextStyle(
                      color: isCurrentMeasure ? AppTheme.accentColor : Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          // 멜로디 노트들 - 남은 공간 사용
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 1,
                  runSpacing: 1,
                  children: notes.map((note) => _buildCompactNoteWidget(note)).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactNoteWidget(dynamic note) {
    final startTime = (note['startTime'] as num).toDouble();
    final endTime = (note['endTime'] as num).toDouble();
    final noteName = note['noteName'] as String;
    final confidence = (note['confidence'] as num).toDouble();
    
    final isCurrentNote = _currentTime >= startTime && _currentTime <= endTime;
    final isPastNote = _currentTime > endTime;
    
    Color backgroundColor;
    Color textColor;
    
    if (isCurrentNote) {
      backgroundColor = AppTheme.accentColor;
      textColor = Colors.black;
    } else if (isPastNote) {
      backgroundColor = Colors.grey.shade600;
      textColor = Colors.white70;
    } else {
      backgroundColor = AppTheme.primaryColor.withOpacity(0.3);
      textColor = Colors.white;
    }
    
    final opacity = (confidence * 0.7 + 0.3).clamp(0.3, 1.0);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(opacity),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isCurrentNote ? AppTheme.accentColor : Colors.transparent,
          width: isCurrentNote ? 1 : 0,
        ),
      ),
      child: Text(
        noteName,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: isCurrentNote ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildMeasureDivider() {
    return Container(
      width: 2,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade600,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
    final List<Widget> noteWidgets = [];
    
    for (int i = 0; i < melodyLine.length; i++) {
      final note = melodyLine[i];
      final startTime = (note['startTime'] as num).toDouble();
      final endTime = (note['endTime'] as num).toDouble();
      final noteName = note['noteName'] as String;
      final confidence = (note['confidence'] as num).toDouble();
      
      final duration = endTime - startTime;
      final width = (duration * 50).clamp(30.0, 150.0); // 최소 30px, 최대 150px
      
      final isCurrentNote = _currentTime >= startTime && _currentTime <= endTime;
      final isPastNote = _currentTime > endTime;
      
      noteWidgets.add(
        _buildNoteCard(
          noteName: noteName,
          startTime: startTime,
          duration: duration,
          confidence: confidence,
          width: width,
          isActive: isCurrentNote,
          isPast: isPastNote,
        ),
      );
      
      // 음표 사이 간격
      if (i < melodyLine.length - 1) {
        noteWidgets.add(const SizedBox(width: 4));
      }
    }
    
    return noteWidgets;
  }

  Widget _buildNoteCard({
    required String noteName,
    required double startTime,
    required double duration,
    required double confidence,
    required double width,
    required bool isActive,
    required bool isPast,
  }) {
    Color backgroundColor;
    Color textColor;
    
    if (isActive) {
      backgroundColor = AppTheme.accentColor;
      textColor = Colors.black;
    } else if (isPast) {
      backgroundColor = Colors.grey.shade600;
      textColor = Colors.white70;
    } else {
      backgroundColor = AppTheme.surfaceColor;
      textColor = Colors.white;
    }
    
    // 신뢰도에 따른 투명도 조절
    final opacity = (confidence * 0.7 + 0.3).clamp(0.3, 1.0);
    
    return Container(
      width: width,
      height: 60,
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(opacity),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive ? AppTheme.accentColor : Colors.grey.shade600,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            noteName,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${startTime.toStringAsFixed(1)}s',
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
          Text(
            '${duration.toStringAsFixed(1)}s',
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToCurrentPosition() {
    if (_scrollController?.hasClients ?? false) {
      // 현재 재생 위치에 따라 스크롤 위치 계산
      final targetOffset = (_currentTime * 50) - (MediaQuery.of(context).size.width / 2);
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

/// 멜로디 라인을 세로로 표시하는 간단한 버전
class CompactMelodyLineWidget extends StatefulWidget {
  final Song song;
  
  const CompactMelodyLineWidget({
    super.key,
    required this.song,
  });

  @override
  State<CompactMelodyLineWidget> createState() => _CompactMelodyLineWidgetState();
}

class _CompactMelodyLineWidgetState extends State<CompactMelodyLineWidget> {
  double _currentTime = 0.0;

  @override
  Widget build(BuildContext context) {
    if (widget.song.pitchAnalysis == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade700),
        ),
        child: const Text(
          '멜로디 데이터 없음',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );
    }

    final melodyLine = widget.song.pitchAnalysis!['melodyLine'] as List<dynamic>? ?? [];
    
    return BlocListener<AudioPlayerBloc, AudioPlayerState>(
      listener: (context, state) {
        if (state.audioState.isPlaying) {
          setState(() {
            _currentTime = state.audioState.currentPosition.inMilliseconds / 1000.0;
          });
        }
      },
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade700),
        ),
        child: Row(
          children: [
            Icon(
              Icons.music_note,
              color: AppTheme.accentColor,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCurrentNoteDisplay(melodyLine),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentNoteDisplay(List<dynamic> melodyLine) {
    // 현재 재생 중인 음표와 마디 정보 찾기
    String currentNote = '-';
    String nextNote = '-';
    double confidence = 0.0;
    int currentMeasure = 0;
    String currentChord = '-';
    
    final secondsPerMeasure = widget.song.structure['secondsPerMeasure'] as double? ?? 1.625;
    final startTime = widget.song.structure['startTimeSeconds'] as double? ?? 13.0;
    final chordProgression = widget.song.chordProgression;
    
    // 현재 마디 계산
    if (_currentTime >= startTime) {
      currentMeasure = ((_currentTime - startTime) / secondsPerMeasure).floor() + 1;
      currentChord = _getChordAtTimeCompact(_currentTime, chordProgression) ?? '-';
    }
    
    for (int i = 0; i < melodyLine.length; i++) {
      final note = melodyLine[i];
      final noteStartTime = (note['startTime'] as num).toDouble();
      final noteEndTime = (note['endTime'] as num).toDouble();
      
      if (_currentTime >= noteStartTime && _currentTime <= noteEndTime) {
        currentNote = note['noteName'] as String;
        confidence = (note['confidence'] as num).toDouble();
        
        // 다음 음표도 찾기
        if (i + 1 < melodyLine.length) {
          nextNote = melodyLine[i + 1]['noteName'] as String;
        }
        break;
      }
    }
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 마디와 코드 정보
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.accentColor, width: 1),
              ),
              child: Text(
                '${currentMeasure}마디',
                style: TextStyle(
                  color: AppTheme.accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                currentChord,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 현재 음표와 다음 음표
        Row(
          children: [
            const Text(
              '현재: ',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              currentNote,
              style: TextStyle(
                color: AppTheme.accentColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              '다음: ',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              nextNote,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (confidence > 0) ...[
          const SizedBox(height: 2),
          LinearProgressIndicator(
            value: confidence,
            backgroundColor: Colors.grey.shade700,
            valueColor: AlwaysStoppedAnimation<Color>(
              confidence > 0.8 ? Colors.green : 
              confidence > 0.6 ? Colors.yellow : Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  String? _getChordAtTimeCompact(double time, Map<String, dynamic> chordProgression) {
    String? currentChord;
    double closestTime = double.negativeInfinity;
    
    for (final entry in chordProgression.entries) {
      final chordTime = double.tryParse(entry.key) ?? 0.0;
      if (chordTime <= time && chordTime > closestTime) {
        closestTime = chordTime;
        currentChord = entry.value as String;
      }
    }
    
    return currentChord;
  }
}

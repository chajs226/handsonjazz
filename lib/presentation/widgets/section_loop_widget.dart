import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/audio_player_bloc.dart';
import '../../app/theme/app_theme.dart';

class SectionLoopWidget extends StatefulWidget {
  const SectionLoopWidget({Key? key}) : super(key: key);

  @override
  State<SectionLoopWidget> createState() => _SectionLoopWidgetState();
}

class _SectionLoopWidgetState extends State<SectionLoopWidget> {
  Duration? _startTime;
  Duration? _endTime;
  bool _isSelectingStart = false;
  bool _isSelectingEnd = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, state) {
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
              Row(
                children: [
                  const Icon(
                    Icons.repeat,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '구간 반복',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (state.hasSectionLoop)
                    IconButton(
                      onPressed: () {
                        context.read<AudioPlayerBloc>().add(ClearSectionLoop());
                        setState(() {
                          _startTime = null;
                          _endTime = null;
                          _isSelectingStart = false;
                          _isSelectingEnd = false;
                        });
                      },
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.white70,
                        size: 20,
                      ),
                      tooltip: '구간 반복 해제',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeButton(
                      label: '시작 지점',
                      time: state.sectionLoopStart ?? _startTime,
                      isSelecting: _isSelectingStart,
                      onPressed: () {
                        final currentPosition = state.audioState.currentPosition;
                        setState(() {
                          _startTime = currentPosition;
                          _isSelectingStart = false;
                        });
                        _updateSectionLoop();
                      },
                      onLongPress: () {
                        setState(() {
                          _isSelectingStart = !_isSelectingStart;
                          _isSelectingEnd = false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimeButton(
                      label: '끝 지점',
                      time: state.sectionLoopEnd ?? _endTime,
                      isSelecting: _isSelectingEnd,
                      onPressed: () {
                        final currentPosition = state.audioState.currentPosition;
                        setState(() {
                          _endTime = currentPosition;
                          _isSelectingEnd = false;
                        });
                        _updateSectionLoop();
                      },
                      onLongPress: () {
                        setState(() {
                          _isSelectingEnd = !_isSelectingEnd;
                          _isSelectingStart = false;
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (state.hasSectionLoop) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.repeat,
                        color: AppTheme.primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '구간 반복 활성화',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeButton({
    required String label,
    required Duration? time,
    required bool isSelecting,
    required VoidCallback onPressed,
    required VoidCallback onLongPress,
  }) {
    return GestureDetector(
      onTap: onPressed,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelecting 
            ? AppTheme.primaryColor.withOpacity(0.3)
            : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelecting 
              ? AppTheme.primaryColor
              : Colors.grey.shade600,
            width: isSelecting ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time != null ? _formatDuration(time) : '--:--',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isSelecting ? '재생 위치에서 설정하려면 탭' : '길게 눌러서 선택 모드',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateSectionLoop() {
    final startTime = _startTime;
    final endTime = _endTime;
    
    if (startTime != null && endTime != null && startTime < endTime) {
      context.read<AudioPlayerBloc>().add(SetSectionLoop(startTime, endTime));
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

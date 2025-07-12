import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/audio_player_bloc.dart';
import '../../data/models/audio_state.dart';
import '../../app/theme/app_theme.dart';

class AudioPlayerWidget extends StatelessWidget {
  const AudioPlayerWidget({Key? key}) : super(key: key);

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
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildControlButtons(context, state),
              const SizedBox(height: 16),
              _buildProgressSlider(context, state),
              const SizedBox(height: 16),
              _buildSpeedControls(context, state),
              const SizedBox(height: 8),
              _buildLoopControls(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButtons(BuildContext context, AudioPlayerState state) {
    final isPlaying = state.audioState.isPlaying;
    final isLoading = state.audioState.isLoading;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: isLoading ? null : () {
            context.read<AudioPlayerBloc>().add(StopAudio());
          },
          icon: const Icon(Icons.stop, color: Colors.white),
          iconSize: 32,
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: isLoading ? null : () {
            if (isPlaying) {
              context.read<AudioPlayerBloc>().add(PauseAudio());
            } else {
              context.read<AudioPlayerBloc>().add(PlayAudio());
            }
          },
          icon: isLoading 
              ? const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(color: AppTheme.secondaryColor),
                )
              : Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
          iconSize: 32,
        ),
      ],
    );
  }

  Widget _buildProgressSlider(BuildContext context, AudioPlayerState state) {
    final currentPosition = state.audioState.currentPosition;
    final totalDuration = state.audioState.totalDuration;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(currentPosition),
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              _formatDuration(totalDuration),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.secondaryColor,
            inactiveTrackColor: Colors.grey.shade600,
            thumbColor: AppTheme.accentColor,
            overlayColor: AppTheme.accentColor.withAlpha(32),
            trackHeight: 4,
          ),
          child: Slider(
            value: totalDuration.inMilliseconds > 0
                ? currentPosition.inMilliseconds / totalDuration.inMilliseconds
                : 0.0,
            onChanged: (value) {
              final seekPosition = Duration(
                milliseconds: (totalDuration.inMilliseconds * value).round(),
              );
              context.read<AudioPlayerBloc>().add(SeekAudio(seekPosition));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedControls(BuildContext context, AudioPlayerState state) {
    final currentSpeed = state.audioState.playbackSpeed;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Speed: ',
          style: TextStyle(color: Colors.white70),
        ),
        ...([0.5, 0.75, 1.0].map((speed) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text('${(speed * 100).toInt()}%'),
              selected: (currentSpeed - speed).abs() < 0.01,
              onSelected: (selected) {
                if (selected) {
                  context.read<AudioPlayerBloc>().add(SetPlaybackSpeed(speed));
                }
              },
              selectedColor: AppTheme.secondaryColor,
              labelStyle: TextStyle(
                color: (currentSpeed - speed).abs() < 0.01 
                    ? Colors.white 
                    : Colors.white70,
              ),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }).toList()),
      ],
    );
  }

  Widget _buildLoopControls(BuildContext context, AudioPlayerState state) {
    final hasLoop = state.audioState.loop != null;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Loop: ',
          style: TextStyle(color: Colors.white70),
        ),
        IconButton(
          onPressed: () {
            if (hasLoop) {
              context.read<AudioPlayerBloc>().add(const SetLoop(null));
            } else {
              // Set a default loop for demonstration
              final currentPosition = state.audioState.currentPosition;
              final loop = LoopData(
                startTime: currentPosition,
                endTime: Duration(
                  milliseconds: currentPosition.inMilliseconds + 30000, // 30 seconds
                ),
              );
              context.read<AudioPlayerBloc>().add(SetLoop(loop));
            }
          },
          icon: Icon(
            hasLoop ? Icons.repeat_on : Icons.repeat,
            color: hasLoop ? AppTheme.accentColor : Colors.white70,
          ),
        ),
        if (hasLoop) ...[
          const SizedBox(width: 8),
          Text(
            '${_formatDuration(state.audioState.loop!.startTime)} - ${_formatDuration(state.audioState.loop!.endTime)}',
            style: const TextStyle(color: AppTheme.accentColor, fontSize: 12),
          ),
        ],
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/audio_player_bloc.dart';
import '../blocs/piano_roll_cubit.dart';
import '../widgets/chord_timeline_widget.dart';
import '../widgets/piano_roll_widget.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/voicing_analysis_widget.dart';
import '../../data/models/song.dart';
import '../../app/theme/app_theme.dart';
import '../../core/di/injection_container.dart' as di;

class PracticeScreen extends StatefulWidget {
  final Song song;

  const PracticeScreen({Key? key, required this.song}) : super(key: key);

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  bool _showAnalysis = false;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AudioPlayerBloc>(
          create: (context) => di.sl<AudioPlayerBloc>()..add(LoadSong(widget.song)),
        ),
        BlocProvider<PianoRollCubit>(
          create: (context) => di.sl<PianoRollCubit>(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.song.title,
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                widget.song.artist,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  _showAnalysis = !_showAnalysis;
                });
              },
              icon: Icon(
                _showAnalysis ? Icons.visibility_off : Icons.visibility,
                color: _showAnalysis ? AppTheme.accentColor : Colors.white70,
              ),
              tooltip: 'Toggle Analysis',
            ),
          ],
        ),
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 800;
              
              if (isWideScreen) {
                return _buildWideLayout();
              } else {
                return _buildNarrowLayout();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  flex: 3, // Give more space to chord timeline (3/5 of the space)
                  child: const ChordTimelineWidget(),
                ),
                const SizedBox(height: 16),
                Expanded(
                  flex: 2, // Less space for piano roll (2/5 of the space)
                  child: const PianoRollWidget(),
                ),
                const SizedBox(height: 16),
                const AudioPlayerWidget(),
              ],
            ),
          ),
        ),
        if (_showAnalysis) ...[
          Container(
            width: 1,
            color: Colors.grey.shade700,
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: const VoicingAnalysisWidget(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            flex: 3, // Give more space to chord timeline (3/6 of available space)
            child: const ChordTimelineWidget(),
          ),
          const SizedBox(height: 16),
          Expanded(
            flex: 2, // Less space for piano roll (2/6 of available space)
            child: const PianoRollWidget(),
          ),
          const SizedBox(height: 16),
          if (_showAnalysis) ...[
            Expanded(
              flex: 1, // Analysis gets minimal space (1/6)
              child: const VoicingAnalysisWidget(),
            ),
            const SizedBox(height: 16),
          ],
          const AudioPlayerWidget(),
        ],
      ),
    );
  }
}

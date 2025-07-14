import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import '../../core/utils/note_converter.dart';
import '../../core/services/audio_analysis_service.dart';

/// 피치 분석 결과를 시각화하는 위젯
class PitchAnalysisWidget extends StatefulWidget {
  final String audioPath;
  final Map<String, dynamic>? pitchData;

  const PitchAnalysisWidget({
    super.key,
    required this.audioPath,
    this.pitchData,
  });

  @override
  State<PitchAnalysisWidget> createState() => _PitchAnalysisWidgetState();
}

class _PitchAnalysisWidgetState extends State<PitchAnalysisWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  AudioAnalysisResult? _analysisResult;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    if (widget.pitchData != null) {
      _loadPitchDataFromJson();
    } else {
      _analyzeAudio();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadPitchDataFromJson() {
    // JSON 데이터에서 피치 정보 로드
    if (widget.pitchData!.containsKey('pitchAnalysis')) {
      final pitchAnalysis = widget.pitchData!['pitchAnalysis'];
      // 여기서 JSON 데이터를 AudioAnalysisResult로 변환
      // 실제 구현에서는 더 완전한 변환이 필요
    }
  }

  Future<void> _analyzeAudio() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final audioAnalysisService = AudioAnalysisService();
      final result = await audioAnalysisService.analyzeAudioFile(widget.audioPath);
      
      setState(() {
        _analysisResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('피치 분석'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '멜로디 라인', icon: Icon(Icons.music_note)),
            Tab(text: '스케일 분석', icon: Icon(Icons.analytics)),
            Tab(text: '계이름 분포', icon: Icon(Icons.pie_chart)),
            Tab(text: '통계', icon: Icon(Icons.bar_chart)),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('음원을 분석하고 있습니다...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _analyzeAudio,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildMelodyLineTab(),
        _buildScaleAnalysisTab(),
        _buildNoteDistributionTab(),
        _buildStatisticsTab(),
      ],
    );
  }

  Widget _buildMelodyLineTab() {
    if (widget.pitchData == null) {
      return const Center(child: Text('피치 데이터가 없습니다.'));
    }

    final melodyLine = widget.pitchData!['pitchAnalysis']?['melodyLine'] ?? [];
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: melodyLine.length,
      itemBuilder: (context, index) {
        final note = melodyLine[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getNoteColor(note['noteName']),
              child: Text(
                note['noteName'].toString().substring(0, 1),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              '${note['noteName']} (${note['frequency'].toStringAsFixed(1)}Hz)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '시간: ${note['startTime'].toStringAsFixed(1)}s - ${note['endTime'].toStringAsFixed(1)}s\n'
              '신뢰도: ${(note['confidence'] * 100).toStringAsFixed(0)}%',
            ),
            trailing: Container(
              width: 60,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: LinearProgressIndicator(
                value: note['confidence'],
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getConfidenceColor(note['confidence']),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScaleAnalysisTab() {
    if (widget.pitchData == null) {
      return const Center(child: Text('피치 데이터가 없습니다.'));
    }

    final scaleAnalysis = widget.pitchData!['pitchAnalysis']?['scaleAnalysis'];
    if (scaleAnalysis == null) {
      return const Center(child: Text('스케일 분석 데이터가 없습니다.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '스케일 분석 결과',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('조성', '${scaleAnalysis['tonicNote']} ${scaleAnalysis['scaleName']}'),
                  _buildInfoRow('신뢰도', '${(scaleAnalysis['confidence'] * 100).toStringAsFixed(1)}%'),
                  _buildInfoRow('설명', scaleAnalysis['description'] ?? ''),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '음계 원',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Center(
                        child: _buildCircleOfFifths(scaleAnalysis['tonicNote']),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteDistributionTab() {
    if (widget.pitchData == null) {
      return const Center(child: Text('피치 데이터가 없습니다.'));
    }

    final noteDistribution = widget.pitchData!['pitchAnalysis']?['noteDistribution'];
    if (noteDistribution == null) {
      return const Center(child: Text('음표 분포 데이터가 없습니다.'));
    }

    final entries = <MapEntry<String, num>>[];
    noteDistribution.forEach((key, value) {
      entries.add(MapEntry(key as String, value as num));
    });
    entries.sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            '계이름별 출현 빈도 (%)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final percentage = entry.value.toDouble();
                
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: percentage / 15, // 최대값 15%로 가정
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getNoteColor(entry.key),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 50,
                          child: Text(
                            '${percentage.toStringAsFixed(1)}%',
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    if (widget.pitchData == null) {
      return const Center(child: Text('피치 데이터가 없습니다.'));
    }

    final statistics = widget.pitchData!['pitchAnalysis']?['statistics'];
    if (statistics == null) {
      return const Center(child: Text('통계 데이터가 없습니다.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '음표 통계',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('총 음표 수', '${statistics['totalNotes']}개'),
                  _buildInfoRow('평균 음표 길이', '${statistics['averageNoteLength'].toStringAsFixed(2)}초'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '음역대',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('최고음', 
                    '${statistics['highestNote']['noteName']} (${statistics['highestNote']['frequency'].toStringAsFixed(1)}Hz)'),
                  _buildInfoRow('최저음', 
                    '${statistics['lowestNote']['noteName']} (${statistics['lowestNote']['frequency'].toStringAsFixed(1)}Hz)'),
                  _buildInfoRow('음역', 
                    '${statistics['range']['semitones']}반음 (${statistics['range']['octaves'].toStringAsFixed(1)}옥타브)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleOfFifths(String tonicNote) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey, width: 2),
      ),
      child: Stack(
        children: [
          // 음계 표시
          Positioned.fill(
            child: CustomPaint(
              painter: CircleOfFifthsPainter(tonicNote),
            ),
          ),
          // 중앙에 조성 표시
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  tonicNote,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getNoteColor(String noteName) {
    final colors = {
      '도': Colors.red,
      '도#': Colors.red[300]!,
      '레': Colors.orange,
      '레#': Colors.orange[300]!,
      '미': Colors.yellow,
      '파': Colors.green,
      '파#': Colors.green[300]!,
      '솔': Colors.blue,
      '솔#': Colors.blue[300]!,
      '라': Colors.indigo,
      '라#': Colors.indigo[300]!,
      '시': Colors.purple,
    };
    
    final noteBase = noteName.replaceAll(RegExp(r'[0-9#♭]'), '');
    return colors[noteBase] ?? Colors.grey;
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.yellow;
    return Colors.red;
  }
}

/// 오음계원을 그리는 CustomPainter
class CircleOfFifthsPainter extends CustomPainter {
  final String tonicNote;
  
  CircleOfFifthsPainter(this.tonicNote);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // 12개 음표 위치 계산
    final notes = ['도', '솔', '레', '라', '미', '시', '파#', '도#', '라♭', '미♭', '시♭', '파'];
    
    for (int i = 0; i < notes.length; i++) {
      final angle = (i * 30 - 90) * (3.14159 / 180); // 30도씩, -90도에서 시작
      final x = center.dx + radius * 0.8 * cos(angle);
      final y = center.dy + radius * 0.8 * sin(angle);
      
      paint.color = notes[i] == tonicNote ? Colors.blue : Colors.grey[300]!;
      
      canvas.drawCircle(Offset(x, y), 15, paint);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: notes[i],
          style: TextStyle(
            color: notes[i] == tonicNote ? Colors.white : Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

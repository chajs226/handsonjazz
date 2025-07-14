import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../widgets/pitch_analysis_widget.dart';

/// 피치 분석 데모 페이지
class PitchAnalysisDemoPage extends StatefulWidget {
  const PitchAnalysisDemoPage({super.key});

  @override
  State<PitchAnalysisDemoPage> createState() => _PitchAnalysisDemoPageState();
}

class _PitchAnalysisDemoPageState extends State<PitchAnalysisDemoPage> {
  Map<String, dynamic>? _jazzData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJazzData();
  }

  Future<void> _loadJazzData() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/there_will_never_be_another_you.json'
      );
      final data = json.decode(jsonString);
      
      setState(() {
        _jazzData = data;
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
        title: const Text('재즈 음원 피치 분석'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
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
            Text('재즈 데이터를 로딩 중...'),
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
            Text('데이터 로딩 오류: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadJazzData,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_jazzData == null) {
      return const Center(
        child: Text('데이터가 없습니다.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSongInfoCard(),
          const SizedBox(height: 16),
          _buildAnalysisCard(),
          const SizedBox(height: 16),
          _buildPitchAnalysisButton(),
        ],
      ),
    );
  }

  Widget _buildSongInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.music_note, size: 32, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _jazzData!['title'] ?? '제목 없음',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '연주: ${_jazzData!['artist'] ?? '연주자 불명'}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip('길이', '${_jazzData!['duration']}초'),
                const SizedBox(width: 8),
                _buildInfoChip('형식', _jazzData!['structure']['form']),
                const SizedBox(width: 8),
                _buildInfoChip('코러스', '${_jazzData!['structure']['choruses'].length}개'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard() {
    final pitchAnalysis = _jazzData!['pitchAnalysis'];
    if (pitchAnalysis == null) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.analytics, size: 48, color: Colors.orange),
              const SizedBox(height: 8),
              const Text(
                '피치 분석 준비됨',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '음원의 멜로디를 분석하여 계이름으로 변환할 수 있습니다.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final scaleAnalysis = pitchAnalysis['scaleAnalysis'];
    final statistics = pitchAnalysis['statistics'];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, size: 24, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  '피치 분석 완료',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('조성', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        '${scaleAnalysis['tonicNote']} ${scaleAnalysis['scaleName']}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('총 음표 수', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        '${statistics['totalNotes']}개',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('신뢰도', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        '${(scaleAnalysis['confidence'] * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('음역대', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        '${statistics['range']['octaves'].toStringAsFixed(1)}옥타브',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPitchAnalysisButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PitchAnalysisWidget(
                audioPath: _jazzData!['audioUrl'],
                pitchData: _jazzData,
              ),
            ),
          );
        },
        icon: const Icon(Icons.show_chart),
        label: const Text(
          '상세 피치 분석 보기',
          style: TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'voicing_data.dart';

part 'song.g.dart';

@JsonSerializable()
class SongStructure extends Equatable {
  final String form;
  final int measuresPerChorus;
  final int secondsPerMeasure;
  final int startTimeSeconds;
  final List<ChorusInfo> choruses;

  const SongStructure({
    required this.form,
    required this.measuresPerChorus,
    required this.secondsPerMeasure,
    required this.startTimeSeconds,
    required this.choruses,
  });

  factory SongStructure.fromJson(Map<String, dynamic> json) => _$SongStructureFromJson(json);
  Map<String, dynamic> toJson() => _$SongStructureToJson(this);

  @override
  List<Object?> get props => [form, measuresPerChorus, secondsPerMeasure, startTimeSeconds, choruses];
}

@JsonSerializable()
class ChorusInfo extends Equatable {
  final int number;
  final int startTime;
  final int endTime;

  const ChorusInfo({
    required this.number,
    required this.startTime,
    required this.endTime,
  });

  factory ChorusInfo.fromJson(Map<String, dynamic> json) => _$ChorusInfoFromJson(json);
  Map<String, dynamic> toJson() => _$ChorusInfoToJson(this);

  @override
  List<Object?> get props => [number, startTime, endTime];
}

@JsonSerializable()
class Song extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final SongStructure structure;
  final List<String> chordChart; // 32마디의 코드 진행 배열
  final Map<String, String> chordProgression; // 시간 -> 코드명
  final Map<String, VoicingData> voicings;    // 코드명 -> 보이싱 데이터
  final int duration; // seconds
  final Map<String, dynamic>? pitchAnalysis; // 피치 분석 데이터 (선택적)

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    required this.structure,
    required this.chordChart,
    required this.chordProgression,
    required this.voicings,
    required this.duration,
    this.pitchAnalysis,
  });

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);

  Map<String, dynamic> toJson() => _$SongToJson(this);

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        audioUrl,
        structure,
        chordChart,
        chordProgression,
        voicings,
        duration,
        pitchAnalysis,
      ];
}

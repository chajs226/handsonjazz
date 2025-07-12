import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'voicing_data.dart';

part 'song.g.dart';

@JsonSerializable()
class Song extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final Map<String, String> chordProgression; // 시간 -> 코드명
  final Map<String, VoicingData> voicings;    // 시간 -> 보이싱 데이터
  final int duration; // seconds

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    required this.chordProgression,
    required this.voicings,
    required this.duration,
  });

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);

  Map<String, dynamic> toJson() => _$SongToJson(this);

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        audioUrl,
        chordProgression,
        voicings,
        duration,
      ];
}

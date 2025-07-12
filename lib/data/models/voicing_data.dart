import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voicing_data.g.dart';

@JsonSerializable()
class VoicingData extends Equatable {
  final List<int> leftHand;  // MIDI note numbers for left hand
  final List<int> rightHand; // MIDI note numbers for right hand
  final String chordSymbol;  // Chord symbol (e.g., "Cmaj7")
  final String analysis;     // 보이싱 분석 정보

  const VoicingData({
    required this.leftHand,
    required this.rightHand,
    required this.chordSymbol,
    required this.analysis,
  });

  factory VoicingData.fromJson(Map<String, dynamic> json) =>
      _$VoicingDataFromJson(json);

  Map<String, dynamic> toJson() => _$VoicingDataToJson(this);

  @override
  List<Object?> get props => [leftHand, rightHand, chordSymbol, analysis];
}

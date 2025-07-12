// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voicing_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoicingData _$VoicingDataFromJson(Map<String, dynamic> json) => VoicingData(
  leftHand: (json['leftHand'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  rightHand: (json['rightHand'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  chordSymbol: json['chordSymbol'] as String,
  analysis: json['analysis'] as String,
);

Map<String, dynamic> _$VoicingDataToJson(VoicingData instance) =>
    <String, dynamic>{
      'leftHand': instance.leftHand,
      'rightHand': instance.rightHand,
      'chordSymbol': instance.chordSymbol,
      'analysis': instance.analysis,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SongStructure _$SongStructureFromJson(Map<String, dynamic> json) =>
    SongStructure(
      form: json['form'] as String,
      measuresPerChorus: (json['measuresPerChorus'] as num).toInt(),
      secondsPerMeasure: (json['secondsPerMeasure'] as num).toInt(),
      startTimeSeconds: (json['startTimeSeconds'] as num).toInt(),
      choruses: (json['choruses'] as List<dynamic>)
          .map((e) => ChorusInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SongStructureToJson(SongStructure instance) =>
    <String, dynamic>{
      'form': instance.form,
      'measuresPerChorus': instance.measuresPerChorus,
      'secondsPerMeasure': instance.secondsPerMeasure,
      'startTimeSeconds': instance.startTimeSeconds,
      'choruses': instance.choruses,
    };

ChorusInfo _$ChorusInfoFromJson(Map<String, dynamic> json) => ChorusInfo(
  number: (json['number'] as num).toInt(),
  startTime: (json['startTime'] as num).toInt(),
  endTime: (json['endTime'] as num).toInt(),
);

Map<String, dynamic> _$ChorusInfoToJson(ChorusInfo instance) =>
    <String, dynamic>{
      'number': instance.number,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
    };

Song _$SongFromJson(Map<String, dynamic> json) => Song(
  id: json['id'] as String,
  title: json['title'] as String,
  artist: json['artist'] as String,
  audioUrl: json['audioUrl'] as String,
  structure: SongStructure.fromJson(json['structure'] as Map<String, dynamic>),
  chordChart: (json['chordChart'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  chordProgression: Map<String, String>.from(json['chordProgression'] as Map),
  voicings: (json['voicings'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, VoicingData.fromJson(e as Map<String, dynamic>)),
  ),
  duration: (json['duration'] as num).toInt(),
  pitchAnalysis: json['pitchAnalysis'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$SongToJson(Song instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'artist': instance.artist,
  'audioUrl': instance.audioUrl,
  'structure': instance.structure,
  'chordChart': instance.chordChart,
  'chordProgression': instance.chordProgression,
  'voicings': instance.voicings,
  'duration': instance.duration,
  'pitchAnalysis': instance.pitchAnalysis,
};

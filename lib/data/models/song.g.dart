// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Song _$SongFromJson(Map<String, dynamic> json) => Song(
  id: json['id'] as String,
  title: json['title'] as String,
  artist: json['artist'] as String,
  audioUrl: json['audioUrl'] as String,
  chordProgression: Map<String, String>.from(json['chordProgression'] as Map),
  voicings: (json['voicings'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, VoicingData.fromJson(e as Map<String, dynamic>)),
  ),
  duration: (json['duration'] as num).toInt(),
);

Map<String, dynamic> _$SongToJson(Song instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'artist': instance.artist,
  'audioUrl': instance.audioUrl,
  'chordProgression': instance.chordProgression,
  'voicings': instance.voicings,
  'duration': instance.duration,
};

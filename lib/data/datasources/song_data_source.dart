import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/song.dart';

abstract class SongDataSource {
  Future<List<Song>> getAllSongs();
  Future<Song> getSongById(String id);
}

class LocalSongDataSource implements SongDataSource {
  @override
  Future<List<Song>> getAllSongs() async {
    // For MVP, we'll load a single song
    final song = await getSongById('there_will_never_be_another_you');
    return [song];
  }

  @override
  Future<Song> getSongById(String id) async {
    try {
      final String response = await rootBundle.loadString('assets/data/$id.json');
      final Map<String, dynamic> data = json.decode(response);
      return Song.fromJson(data);
    } catch (e) {
      throw Exception('Failed to load song: $e');
    }
  }
}

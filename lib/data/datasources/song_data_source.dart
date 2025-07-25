import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/song.dart';

abstract class SongDataSource {
  Future<List<Song>> getAllSongs();
  Future<Song> getSongById(String id);
}

class LocalSongDataSource implements SongDataSource {
  // Available song IDs - add new songs here when they're processed
  static const List<String> _availableSongs = [
    'there_will_never_be_another_you',
    'bill_evans_everything_happens_to_me',
  ];

  @override
  Future<List<Song>> getAllSongs() async {
    final List<Song> songs = [];
    
    for (final songId in _availableSongs) {
      try {
        final song = await getSongById(songId);
        songs.add(song);
      } catch (e) {
        // Skip songs that fail to load
        print('Failed to load song $songId: $e');
      }
    }
    
    return songs;
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

import '../../data/models/song.dart';

abstract class SongRepository {
  Future<List<Song>> getAllSongs();
  Future<Song> getSongById(String id);
}

import '../../domain/repositories/song_repository.dart';
import '../datasources/song_data_source.dart';
import '../models/song.dart';

class SongRepositoryImpl implements SongRepository {
  final SongDataSource dataSource;

  SongRepositoryImpl({required this.dataSource});

  @override
  Future<List<Song>> getAllSongs() async {
    return await dataSource.getAllSongs();
  }

  @override
  Future<Song> getSongById(String id) async {
    return await dataSource.getSongById(id);
  }
}

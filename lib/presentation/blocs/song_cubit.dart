import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/song_repository.dart';
import '../../data/models/song.dart';

// State
abstract class SongState extends Equatable {
  const SongState();

  @override
  List<Object> get props => [];
}

class SongInitial extends SongState {}

class SongLoading extends SongState {}

class SongLoaded extends SongState {
  final List<Song> songs;

  const SongLoaded(this.songs);

  @override
  List<Object> get props => [songs];
}

class SongError extends SongState {
  final String message;

  const SongError(this.message);

  @override
  List<Object> get props => [message];
}

// Cubit
class SongCubit extends Cubit<SongState> {
  final SongRepository _repository;

  SongCubit({required SongRepository repository})
      : _repository = repository,
        super(SongInitial());

  Future<void> loadSongs() async {
    try {
      emit(SongLoading());
      final songs = await _repository.getAllSongs();
      emit(SongLoaded(songs));
    } catch (e) {
      emit(SongError(e.toString()));
    }
  }

  Future<Song?> getSongById(String id) async {
    try {
      return await _repository.getSongById(id);
    } catch (e) {
      emit(SongError(e.toString()));
      return null;
    }
  }
}

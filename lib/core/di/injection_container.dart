import 'package:get_it/get_it.dart';
import '../../data/datasources/song_data_source.dart';
import '../../data/repositories/song_repository_impl.dart';
import '../../domain/repositories/song_repository.dart';
import '../services/audio_service.dart';
import '../services/timing_service.dart';
import '../../presentation/blocs/audio_player_bloc.dart';
import '../../presentation/blocs/piano_roll_cubit.dart';
import '../../presentation/blocs/song_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Data sources
  sl.registerLazySingleton<SongDataSource>(() => LocalSongDataSource());

  // Repositories
  sl.registerLazySingleton<SongRepository>(
    () => SongRepositoryImpl(dataSource: sl()),
  );

  // Services
  sl.registerLazySingleton<AudioService>(() => AudioService());
  sl.registerLazySingleton<TimingService>(() => TimingService());

  // BLoCs
  sl.registerFactory(() => SongCubit(repository: sl()));
  sl.registerFactory(() => AudioPlayerBloc(
        audioService: sl(),
        timingService: sl(),
      ));
  sl.registerFactory(() => PianoRollCubit(timingService: sl()));
}

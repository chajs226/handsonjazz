import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../presentation/pages/home_screen.dart';
import '../presentation/blocs/song_cubit.dart';
import 'theme/app_theme.dart';
import '../core/di/injection_container.dart' as di;

class HandsOnJazzApp extends StatelessWidget {
  const HandsOnJazzApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SongCubit>(
          create: (context) => di.sl<SongCubit>(),
        ),
      ],
      child: MaterialApp(
        title: 'handsOnJazz',
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

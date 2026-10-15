import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/app_theme.dart';
import 'data/repositories/exercise_repository.dart';
import 'data/repositories/favorite_repository.dart';
import 'data/repositories/routine_repository.dart';
import 'features/exercises/bloc/exercises_bloc.dart';
import 'features/exercises/bloc/exercises_event.dart';
import 'features/routines/bloc/routines_bloc.dart';
import 'features/routines/bloc/routines_event.dart';
import 'features/shell/home_shell.dart';
import 'features/workout/bloc/workout_bloc.dart';

/// Root widget. Repositories are injected once here; the blocs that outlive a
/// single tab (exercises, workout, routines) are created above [MaterialApp]
/// so every route can reach them.
class GymBodyApp extends StatelessWidget {
  const GymBodyApp({
    super.key,
    required this.exerciseRepository,
    required this.favoriteRepository,
    required this.routineRepository,
  });

  final ExerciseRepository exerciseRepository;
  final FavoriteRepository favoriteRepository;
  final RoutineRepository routineRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ExerciseRepository>.value(value: exerciseRepository),
        RepositoryProvider<FavoriteRepository>.value(value: favoriteRepository),
        RepositoryProvider<RoutineRepository>.value(value: routineRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ExercisesBloc>(
            create: (_) =>
                ExercisesBloc(repository: exerciseRepository, favorites: favoriteRepository)
                  ..add(const ExercisesLoadRequested()),
          ),
          BlocProvider<WorkoutBloc>(create: (_) => WorkoutBloc()),
          BlocProvider<RoutinesBloc>(
            create: (_) => RoutinesBloc(repository: routineRepository)..add(const RoutinesLoadRequested()),
          ),
        ],
        child: MaterialApp(
          title: 'GymBody',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const HomeShell(),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/exercise.dart';
import '../../../domain/models/routine.dart';
import '../../exercises/bloc/exercises_state.dart';
import '../../shell/home_tab_scope.dart';
import '../../workout/bloc/workout_bloc.dart';
import '../../workout/bloc/workout_event.dart';
import '../bloc/routines_bloc.dart';
import '../bloc/routines_event.dart';
import 'widgets/rename_routine_dialog.dart';

/// Shared routine helpers used by both the list and the detail page.

Routine? findRoutineById(List<Routine> routines, int id) {
  for (final routine in routines) {
    if (routine.id == id) return routine;
  }
  return null;
}

/// Resolves routine entries against the loaded catalogue, skipping ids whose
/// custom exercise was deleted.
List<Exercise> resolveRoutineExercises(Routine routine, ExercisesState state) {
  final resolved = <Exercise>[];
  for (final id in routine.exerciseIds) {
    final exercise = state.byId(id);
    if (exercise != null) resolved.add(exercise);
  }
  return resolved;
}

/// One-line summary of a routine's content, e.g. `Bench press, Squat +2`.
String routinePreview(Routine routine, ExercisesState state) {
  if (routine.exerciseIds.isEmpty) return 'No exercises yet';

  final names = <String>[];
  for (final id in routine.exerciseIds.take(3)) {
    names.add(state.byId(id)?.name ?? 'Unknown exercise');
  }
  final remaining = routine.exerciseIds.length - names.length;
  final joined = names.join(', ');
  return remaining > 0 ? '$joined +$remaining' : joined;
}

void startRoutineAsWorkout(BuildContext context, Routine routine, ExercisesState state) {
  final resolved = resolveRoutineExercises(routine, state);
  final workoutBloc = context.read<WorkoutBloc>();
  final messenger = ScaffoldMessenger.of(context);
  final tabScope = HomeTabScope.maybeOf(context);

  workoutBloc.add(WorkoutStarted(exercises: resolved));
  tabScope?.selectTab(HomeTabs.workout);
  messenger.showSnackBar(SnackBar(content: Text('Started "${routine.name}"')));
}

Future<void> renameRoutine(BuildContext context, Routine routine) async {
  final bloc = context.read<RoutinesBloc>();
  final name = await RenameRoutineDialog.show(context, routine.name);
  if (name == null) return;
  bloc.add(RoutineRenamed(id: routine.id, name: name));
}

Future<void> deleteRoutine(BuildContext context, Routine routine) async {
  final bloc = context.read<RoutinesBloc>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete routine?'),
      content: Text('"${routine.name}" will be permanently removed.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
      ],
    ),
  );
  if (confirmed == true) bloc.add(RoutineDeleted(routine.id));
}

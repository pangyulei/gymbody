import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/exercise_image.dart';
import '../../../domain/models/exercise.dart';
import '../../exercises/bloc/exercises_bloc.dart';
import '../../workout/view/add_exercise_page.dart';
import '../bloc/routines_bloc.dart';
import '../bloc/routines_event.dart';
import '../bloc/routines_state.dart';
import 'routine_actions.dart';

/// Detail of a single routine: reorder, remove and add exercises, rename or
/// delete it, and start a workout from it.
class RoutineDetailPage extends StatelessWidget {
  const RoutineDetailPage({super.key, required this.routineId});

  final int routineId;

  Future<void> _addExercises(BuildContext context) async {
    final routinesBloc = context.read<RoutinesBloc>();
    if (findRoutineById(routinesBloc.state.routines, routineId) == null) return;

    final selected = await Navigator.of(context)
        .push<List<Exercise>>(MaterialPageRoute(builder: (_) => const AddExercisePage(title: 'Add to routine')));
    if (selected == null || selected.isEmpty) return;

    // Re-read the routine so edits made while the picker was open are kept.
    final routine = findRoutineById(routinesBloc.state.routines, routineId);
    if (routine == null) return;

    routinesBloc.add(
      RoutineExercisesUpdated(id: routineId, exerciseIds: [...routine.exerciseIds, ...selected.map((e) => e.id)]),
    );
  }

  void _removeAt(BuildContext context, List<String> ids, int index) {
    final updated = [...ids]..removeAt(index);
    context.read<RoutinesBloc>().add(RoutineExercisesUpdated(id: routineId, exerciseIds: updated));
  }

  void _reorder(BuildContext context, List<String> ids, int oldIndex, int newIndex) {
    final updated = [...ids];
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);
    context.read<RoutinesBloc>().add(RoutineExercisesUpdated(id: routineId, exerciseIds: updated));
  }

  /// Stable, unique keys for [ReorderableListView]. A routine can legitimately
  /// contain the same exercise twice, so the occurrence is part of the key.
  List<String> _itemKeys(List<String> ids) {
    final seen = <String, int>{};
    return [for (final id in ids) 'routine-$routineId-$id-${seen.update(id, (count) => count + 1, ifAbsent: () => 0)}'];
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoutinesBloc, RoutinesState>(
      listenWhen: (previous, current) =>
          findRoutineById(previous.routines, routineId) != null && findRoutineById(current.routines, routineId) == null,
      listener: (context, state) => Navigator.of(context).maybePop(),
      builder: (context, state) {
        final routine = findRoutineById(state.routines, routineId);
        if (routine == null) {
          return const Scaffold(body: SizedBox.shrink());
        }

        final exercises = context.watch<ExercisesBloc>().state;
        final theme = Theme.of(context);
        final itemKeys = _itemKeys(routine.exerciseIds);

        return Scaffold(
          appBar: AppBar(
            title: Text(routine.name),
            actions: [
              IconButton(
                tooltip: 'Rename',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => renameRoutine(context, routine),
              ),
              IconButton(
                tooltip: 'Delete routine',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => deleteRoutine(context, routine),
              ),
            ],
          ),
          body: routine.exerciseIds.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'This routine is empty.\nAdd a few exercises to get started.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          Text(
                            '${routine.exerciseCount} exercise'
                            '${routine.exerciseCount == 1 ? '' : 's'}',
                            style: theme.textTheme.titleSmall,
                          ),
                          const Spacer(),
                          Text(
                            'Drag to reorder',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: routine.exerciseIds.length,
                        onReorderItem: (oldIndex, newIndex) =>
                            _reorder(context, routine.exerciseIds, oldIndex, newIndex),
                        itemBuilder: (context, index) {
                          final id = routine.exerciseIds[index];
                          final exercise = exercises.byId(id);

                          return ListTile(
                            key: ValueKey(itemKeys[index]),
                            contentPadding: const EdgeInsets.only(left: 8, right: 8),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: ExerciseImage(posterPath: exercise?.posterPath, gifPath: exercise?.gifPath),
                              ),
                            ),
                            title: Text(exercise?.name ?? 'Unknown exercise'),
                            subtitle: exercise == null
                                ? const Text('Unavailable')
                                : Text(
                                    [
                                      if (exercise.bodyPart.isNotEmpty) exercise.bodyPart,
                                      if (exercise.equipment.isNotEmpty) exercise.equipment,
                                    ].join(' · '),
                                  ),
                            trailing: IconButton(
                              tooltip: 'Remove from routine',
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _removeAt(context, routine.exerciseIds, index),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addExercises(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add exercises'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => startRoutineAsWorkout(context, routine, exercises),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start workout'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

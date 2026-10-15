import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../exercises/bloc/exercises_bloc.dart';
import '../bloc/routines_bloc.dart';
import '../bloc/routines_state.dart';
import 'routine_actions.dart';
import 'routine_detail_page.dart';

enum _RoutineAction { start, rename, delete }

/// Tab 3: the routines the user saved from finished workouts.
class RoutinesPage extends StatelessWidget {
  const RoutinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final exercises = context.watch<ExercisesBloc>().state;

    return BlocBuilder<RoutinesBloc, RoutinesState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Routines')),
          body: state.routines.isEmpty
              ? const _EmptyRoutines()
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 32),
                  itemCount: state.routines.length,
                  itemBuilder: (context, index) {
                    final routine = state.routines[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(routine.name),
                        subtitle: Text(
                          '${routine.exerciseCount} exercise'
                          '${routine.exerciseCount == 1 ? '' : 's'} · '
                          '${routinePreview(routine, exercises)}',
                        ),
                        trailing: PopupMenuButton<_RoutineAction>(
                          onSelected: (action) => switch (action) {
                            _RoutineAction.start => startRoutineAsWorkout(context, routine, exercises),
                            _RoutineAction.rename => renameRoutine(context, routine),
                            _RoutineAction.delete => deleteRoutine(context, routine),
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _RoutineAction.start,
                              child: ListTile(
                                leading: Icon(Icons.play_arrow),
                                title: Text('Start workout'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: _RoutineAction.rename,
                              child: ListTile(
                                leading: Icon(Icons.edit_outlined),
                                title: Text('Rename'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: _RoutineAction.delete,
                              child: ListTile(
                                leading: Icon(Icons.delete_outline),
                                title: Text('Delete'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        onTap: () =>
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => RoutineDetailPage(routineId: routine.id))),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _EmptyRoutines extends StatelessWidget {
  const _EmptyRoutines();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.list_alt_outlined, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No routines yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Finish a workout and save it as a routine to see it here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

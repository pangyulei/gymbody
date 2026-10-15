import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/exercise.dart';
import '../../../domain/models/workout_session.dart';
import '../../routines/bloc/routines_bloc.dart';
import '../../routines/bloc/routines_event.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import 'add_exercise_page.dart';
import 'widgets/workout_gallery.dart';

enum _FinishAction { save, discard }

/// Tab 2: the workout the user is building.
class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final TextEditingController _routineNameController = TextEditingController();

  @override
  void dispose() {
    _routineNameController.dispose();
    super.dispose();
  }

  Future<void> _addExercises() async {
    final workoutBloc = context.read<WorkoutBloc>();
    final selected = await Navigator.of(context)
        .push<List<Exercise>>(MaterialPageRoute(builder: (_) => const AddExercisePage()));
    if (selected == null || selected.isEmpty) return;
    workoutBloc.add(WorkoutExercisesAdded(selected));
  }

  Future<void> _discard() async {
    final workoutBloc = context.read<WorkoutBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard workout?'),
        content: const Text('The exercises you added will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Discard')),
        ],
      ),
    );
    if (confirmed == true) workoutBloc.add(const WorkoutFinished());
  }

  /// Ends the session, optionally turning it into a routine.
  Future<void> _finish() async {
    final workoutBloc = context.read<WorkoutBloc>();
    final routinesBloc = context.read<RoutinesBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final session = workoutBloc.state;

    _routineNameController.text = 'My workout';

    final action = await showDialog<_FinishAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish workout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${session.exercises.length} '
              'exercise${session.exercises.length == 1 ? '' : 's'}',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _routineNameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Routine name'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(_FinishAction.discard), child: const Text('Discard')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_FinishAction.save),
            child: const Text('Save as routine'),
          ),
        ],
      ),
    );

    if (action == null) return;

    if (action == _FinishAction.save) {
      final name = _routineNameController.text.trim();
      routinesBloc.add(
        RoutineSaveRequested(name: name.isEmpty ? 'My workout' : name, exerciseIds: session.exerciseIds),
      );
      messenger.showSnackBar(SnackBar(content: Text('Saved "${name.isEmpty ? 'My workout' : name}"')));
    }

    workoutBloc.add(const WorkoutFinished());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutBloc, WorkoutSession>(
      builder: (context, session) {
        final isActive = session.status == WorkoutStatus.active;

        if (!isActive) {
          return Scaffold(
            appBar: AppBar(title: const Text('Workout')),
            body: _EmptyWorkout(onStart: () => context.read<WorkoutBloc>().add(const WorkoutStarted())),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Workout'),
                Row(
                  children: [
                    Text(
                      '${session.exercises.length} '
                      'exercise${session.exercises.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(' · ', style: Theme.of(context).textTheme.bodySmall),
                    _ElapsedLabel(startedAt: session.startedAt),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(tooltip: 'Discard workout', icon: const Icon(Icons.delete_outline), onPressed: _discard),
            ],
          ),
          body: session.exercises.isEmpty
              ? _EmptySession(onAdd: _addExercises)
              : WorkoutGallery(exercises: session.exercises, currentIndex: session.currentIndex),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addExercises,
                    icon: const Icon(Icons.add),
                    label: const Text('Add exercise'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: session.hasExercises ? _finish : null,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Finish'),
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

class _EmptyWorkout extends StatelessWidget {
  const _EmptyWorkout({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('No workout in progress', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Start an empty workout, then add exercises as you go.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start empty workout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySession extends StatelessWidget {
  const _EmptySession({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_add, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Your workout is empty', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Add the first exercise to get started.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add exercise')),
          ],
        ),
      ),
    );
  }
}

/// Ticking session timer shown next to the exercise count.
class _ElapsedLabel extends StatefulWidget {
  const _ElapsedLabel({required this.startedAt});

  final DateTime? startedAt;

  @override
  State<_ElapsedLabel> createState() => _ElapsedLabelState();
}

class _ElapsedLabelState extends State<_ElapsedLabel> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _elapsed = _computeElapsed();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _ElapsedLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startedAt != oldWidget.startedAt) {
      _elapsed = _computeElapsed();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.startedAt == null) {
      _timer = null;
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _elapsed = _computeElapsed());
  }

  Duration _computeElapsed() {
    final startedAt = widget.startedAt;
    return startedAt == null ? Duration.zero : DateTime.now().difference(startedAt);
  }

  @override
  Widget build(BuildContext context) {
    final hours = _elapsed.inHours;
    final minutes = _elapsed.inMinutes.remainder(60);
    final seconds = _elapsed.inSeconds.remainder(60);
    final text = hours > 0 ? '$hours:${_two(minutes)}:${_two(seconds)}' : '${_two(minutes)}:${_two(seconds)}';

    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/exercise_image.dart';
import '../../../domain/models/exercise.dart';
import '../../workout/bloc/workout_bloc.dart';
import '../../workout/bloc/workout_event.dart';
import '../bloc/exercises_bloc.dart';
import '../bloc/exercises_event.dart';
import '../bloc/exercises_state.dart';

enum _DetailAction { addToWorkout, delete }

/// Full details of a single exercise: animated instruction, tags and steps.
class ExerciseDetailPage extends StatelessWidget {
  const ExerciseDetailPage({super.key, required this.exercise});

  final Exercise exercise;

  Future<void> _confirmDelete(BuildContext context) async {
    final bloc = context.read<ExercisesBloc>();
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete exercise?'),
        content: Text('"${exercise.name}" and its saved poster/animation will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return;
    bloc.add(ExerciseDeleted(exercise.id));
    navigator.pop();
  }

  void _addToWorkout(BuildContext context) {
    context.read<WorkoutBloc>().add(WorkoutExerciseAdded(exercise));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${exercise.name}" added to your workout')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ExercisesBloc, ExercisesState>(
      buildWhen: (previous, current) => previous.favoriteIds != current.favoriteIds,
      builder: (context, state) {
        final isFavorite = state.isFavorite(exercise.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(exercise.name),
            actions: [
              IconButton(
                tooltip: isFavorite ? 'Remove from favorites' : 'Mark as favorite',
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? theme.colorScheme.error : null,
                ),
                onPressed: () => context.read<ExercisesBloc>().add(ExerciseFavoriteToggled(exercise.id)),
              ),
              PopupMenuButton<_DetailAction>(
                onSelected: (action) => switch (action) {
                  _DetailAction.addToWorkout => _addToWorkout(context),
                  _DetailAction.delete => _confirmDelete(context),
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _DetailAction.addToWorkout,
                    child: ListTile(
                      leading: Icon(Icons.add),
                      title: Text('Add to workout'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (exercise.isCustom)
                    const PopupMenuItem(
                      value: _DetailAction.delete,
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('Delete exercise'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: ExerciseImage(
                        posterPath: exercise.posterPath,
                        gifPath: exercise.gifPath,
                        animate: true,
                        fit: BoxFit.contain,
                        icon: Icons.fitness_center,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (exercise.bodyPart.isNotEmpty) _Tag(icon: Icons.accessibility_new, label: exercise.bodyPart),
                    if (exercise.equipment.isNotEmpty) _Tag(icon: Icons.fitness_center, label: exercise.equipment),
                    if (exercise.target.isNotEmpty) _Tag(icon: Icons.adjust, label: exercise.target),
                    if (exercise.muscleGroup.isNotEmpty) _Tag(icon: Icons.bolt, label: exercise.muscleGroup),
                    if (exercise.isCustom) const _Tag(icon: Icons.person_outline, label: 'Custom'),
                  ],
                ),
              ),
              if (exercise.secondaryMuscles.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    'Secondary muscles: ${exercise.secondaryMuscles.join(', ')}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Instructions', style: theme.textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              if (exercise.instructionSteps.isNotEmpty)
                ...exercise.instructionSteps.indexed.map(
                  (entry) => _InstructionStep(index: entry.$1 + 1, text: entry.$2),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    exercise.instructions.isEmpty ? 'No instructions provided.' : exercise.instructions,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              const SizedBox(height: 96),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () => _addToWorkout(context),
              icon: const Icon(Icons.add),
              label: const Text('Add to workout'),
            ),
          ),
        );
      },
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              '$index',
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

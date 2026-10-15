import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/exercise_image.dart';
import '../../../../domain/models/exercise.dart';
import '../../../exercises/bloc/exercises_bloc.dart';
import '../../../exercises/bloc/exercises_event.dart';
import '../../../exercises/bloc/exercises_state.dart';
import '../../bloc/workout_bloc.dart';
import '../../bloc/workout_event.dart';

/// Gallery of the exercises in the current workout.
///
/// Exercises are shown one per page; the prev/next buttons (and horizontal
/// swipes) move between them. [WorkoutBloc] remains the source of truth for
/// the current index.
class WorkoutGallery extends StatefulWidget {
  const WorkoutGallery({super.key, required this.exercises, required this.currentIndex});

  final List<Exercise> exercises;
  final int currentIndex;

  @override
  State<WorkoutGallery> createState() => _WorkoutGalleryState();
}

class _WorkoutGalleryState extends State<WorkoutGallery> {
  late final PageController _controller = PageController(initialPage: widget.currentIndex);

  /// True while we are animating the controller ourselves, so the resulting
  /// `onPageChanged` callbacks are not echoed back to the bloc.
  bool _programmatic = false;

  @override
  void didUpdateWidget(covariant WorkoutGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex || widget.exercises.length != oldWidget.exercises.length) {
      _animateTo(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(int index) {
    if (!_controller.hasClients) return;
    final current = _controller.page?.round() ?? _controller.initialPage;
    if (current == index) return;

    _programmatic = true;
    _controller.animateToPage(index, duration: const Duration(milliseconds: 280), curve: Curves.easeInOut).whenComplete(
      () {
        if (mounted) _programmatic = false;
      },
    );
  }

  void _step(int delta) {
    context.read<WorkoutBloc>().add(WorkoutStepRequested(delta));
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.exercises.length;

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: count,
                onPageChanged: (index) {
                  if (_programmatic) return;
                  context.read<WorkoutBloc>().add(WorkoutPageChanged(index));
                },
                itemBuilder: (context, index) => _GalleryPage(exercise: widget.exercises[index]),
              ),
              if (count > 1) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: _NavButton(tooltip: 'Previous exercise', icon: Icons.chevron_left, onPressed: () => _step(-1)),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: _NavButton(tooltip: 'Next exercise', icon: Icons.chevron_right, onPressed: () => _step(1)),
                ),
              ],
            ],
          ),
        ),
        _DotsIndicator(count: count, index: widget.currentIndex),
      ],
    );
  }
}

class _GalleryPage extends StatelessWidget {
  const _GalleryPage({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
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
          const SizedBox(height: 16),
          Text(exercise.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (exercise.bodyPart.isNotEmpty)
                Chip(avatar: const Icon(Icons.accessibility_new, size: 18), label: Text(exercise.bodyPart)),
              if (exercise.equipment.isNotEmpty)
                Chip(avatar: const Icon(Icons.fitness_center, size: 18), label: Text(exercise.equipment)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              BlocBuilder<ExercisesBloc, ExercisesState>(
                builder: (context, state) {
                  final isFavorite = state.isFavorite(exercise.id);
                  return TextButton.icon(
                    onPressed: () => context.read<ExercisesBloc>().add(ExerciseFavoriteToggled(exercise.id)),
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? theme.colorScheme.error : null,
                    ),
                    label: Text(isFavorite ? 'Favorited' : 'Favorite'),
                  );
                },
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.read<WorkoutBloc>().add(
                  WorkoutExerciseRemoved(context.read<WorkoutBloc>().state.currentIndex),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove'),
              ),
            ],
          ),
          if (exercise.instructionSteps.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Instructions', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            for (final step in exercise.instructionSteps)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.arrow_right, size: 20),
                    const SizedBox(width: 4),
                    Expanded(child: Text(step, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
          ] else if (exercise.instructions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Instructions', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(exercise.instructions, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.tooltip, required this.icon, required this.onPressed});

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: scheme.surface.withValues(alpha: 0.85),
        shape: const CircleBorder(),
        child: IconButton(tooltip: tooltip, icon: Icon(icon), onPressed: onPressed),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == index ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:equatable/equatable.dart';

import '../../../domain/models/exercise.dart';

sealed class WorkoutEvent extends Equatable {
  const WorkoutEvent();

  @override
  List<Object?> get props => [];
}

/// Starts a new session, optionally pre-filled (e.g. from a routine).
class WorkoutStarted extends WorkoutEvent {
  const WorkoutStarted({this.exercises = const []});

  final List<Exercise> exercises;

  @override
  List<Object?> get props => [exercises];
}

class WorkoutExerciseAdded extends WorkoutEvent {
  const WorkoutExerciseAdded(this.exercise);

  final Exercise exercise;

  @override
  List<Object?> get props => [exercise];
}

/// Appends several exercises at once (e.g. a multi selection or a routine).
class WorkoutExercisesAdded extends WorkoutEvent {
  const WorkoutExercisesAdded(this.exercises);

  final List<Exercise> exercises;

  @override
  List<Object?> get props => [exercises];
}

class WorkoutExerciseRemoved extends WorkoutEvent {
  const WorkoutExerciseRemoved(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

/// Jumps to a specific page of the gallery.
class WorkoutPageChanged extends WorkoutEvent {
  const WorkoutPageChanged(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

/// Moves the gallery left/right. [delta] is typically -1 or 1.
class WorkoutStepRequested extends WorkoutEvent {
  const WorkoutStepRequested(this.delta);

  final int delta;

  @override
  List<Object?> get props => [delta];
}

/// Ends the session and clears it.
class WorkoutFinished extends WorkoutEvent {
  const WorkoutFinished();
}

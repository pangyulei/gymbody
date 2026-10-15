import 'package:equatable/equatable.dart';

import 'exercise.dart';

enum WorkoutStatus { empty, active, finished }

/// In-memory state of the workout the user is currently building.
///
/// Only exercise ids are kept so the session can be turned into a routine
/// verbatim. Exercises are resolved eagerly to [Exercise]s so the gallery can
/// render without extra lookups.
class WorkoutSession extends Equatable {
  const WorkoutSession({
    this.exercises = const [],
    this.currentIndex = 0,
    this.status = WorkoutStatus.empty,
    this.startedAt,
  });

  final List<Exercise> exercises;
  final int currentIndex;
  final WorkoutStatus status;
  final DateTime? startedAt;

  bool get isEmpty => exercises.isEmpty;
  bool get hasExercises => exercises.isNotEmpty;

  Exercise? get current {
    if (exercises.isEmpty) return null;
    final index = currentIndex.clamp(0, exercises.length - 1);
    return exercises[index];
  }

  List<String> get exerciseIds => exercises.map((e) => e.id).toList(growable: false);

  WorkoutSession copyWith({List<Exercise>? exercises, int? currentIndex, WorkoutStatus? status, DateTime? startedAt}) {
    final nextExercises = exercises ?? this.exercises;
    final maxIndex = nextExercises.isEmpty ? 0 : nextExercises.length - 1;
    return WorkoutSession(
      exercises: nextExercises,
      currentIndex: (currentIndex ?? this.currentIndex).clamp(0, maxIndex),
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  @override
  List<Object?> get props => [exercises, currentIndex, status, startedAt];
}

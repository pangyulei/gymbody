import 'package:equatable/equatable.dart';

sealed class RoutinesEvent extends Equatable {
  const RoutinesEvent();

  @override
  List<Object?> get props => [];
}

class RoutinesLoadRequested extends RoutinesEvent {
  const RoutinesLoadRequested();
}

/// Creates a routine, e.g. when saving a finished workout.
class RoutineSaveRequested extends RoutinesEvent {
  const RoutineSaveRequested({required this.name, required this.exerciseIds});

  final String name;
  final List<String> exerciseIds;

  @override
  List<Object?> get props => [name, exerciseIds];
}

class RoutineRenamed extends RoutinesEvent {
  const RoutineRenamed({required this.id, required this.name});

  final int id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

class RoutineExercisesUpdated extends RoutinesEvent {
  const RoutineExercisesUpdated({required this.id, required this.exerciseIds});

  final int id;
  final List<String> exerciseIds;

  @override
  List<Object?> get props => [id, exerciseIds];
}

class RoutineDeleted extends RoutinesEvent {
  const RoutineDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

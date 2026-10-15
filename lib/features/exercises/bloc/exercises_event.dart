import 'package:equatable/equatable.dart';

sealed class ExercisesEvent extends Equatable {
  const ExercisesEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the bundled dataset plus the user's custom exercises.
class ExercisesLoadRequested extends ExercisesEvent {
  const ExercisesLoadRequested();
}

class ExercisesSearchChanged extends ExercisesEvent {
  const ExercisesSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class ExercisesBodyPartToggled extends ExercisesEvent {
  const ExercisesBodyPartToggled(this.bodyPart);

  final String bodyPart;

  @override
  List<Object?> get props => [bodyPart];
}

class ExercisesEquipmentToggled extends ExercisesEvent {
  const ExercisesEquipmentToggled(this.equipment);

  final String equipment;

  @override
  List<Object?> get props => [equipment];
}

class ExercisesSelectionCleared extends ExercisesEvent {
  const ExercisesSelectionCleared();
}

/// Adds or removes a favorite.
class ExerciseFavoriteToggled extends ExercisesEvent {
  const ExerciseFavoriteToggled(this.exerciseId);

  final String exerciseId;

  @override
  List<Object?> get props => [exerciseId];
}

/// Signals that a custom exercise was created and the list must be reloaded.
class ExercisesCustomAdded extends ExercisesEvent {
  const ExercisesCustomAdded();
}

/// Deletes a custom exercise (dataset ids are ignored).
class ExerciseDeleted extends ExercisesEvent {
  const ExerciseDeleted(this.exerciseId);

  final String exerciseId;

  @override
  List<Object?> get props => [exerciseId];
}

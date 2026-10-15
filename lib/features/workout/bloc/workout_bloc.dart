import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/exercise.dart';
import '../../../domain/models/workout_session.dart';
import 'workout_event.dart';

/// Holds the workout the user is currently building.
///
/// The state is the [WorkoutSession] itself, so the gallery only has to read
/// `exercises` / `currentIndex`.
class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutSession> {
  WorkoutBloc() : super(const WorkoutSession()) {
    on<WorkoutStarted>(_onStarted);
    on<WorkoutExerciseAdded>(_onAdded);
    on<WorkoutExercisesAdded>(_onManyAdded);
    on<WorkoutExerciseRemoved>(_onRemoved);
    on<WorkoutPageChanged>((event, emit) => emit(state.copyWith(currentIndex: event.index)));
    on<WorkoutStepRequested>(_onStep);
    on<WorkoutFinished>((event, emit) => emit(const WorkoutSession()));
  }

  void _onStarted(WorkoutStarted event, Emitter<WorkoutSession> emit) {
    emit(
      WorkoutSession(
        exercises: List<Exercise>.of(event.exercises),
        status: WorkoutStatus.active,
        startedAt: DateTime.now(),
      ),
    );
  }

  void _onAdded(WorkoutExerciseAdded event, Emitter<WorkoutSession> emit) {
    _emitAdded(emit, [event.exercise]);
  }

  void _onManyAdded(WorkoutExercisesAdded event, Emitter<WorkoutSession> emit) {
    if (event.exercises.isEmpty) return;
    _emitAdded(emit, event.exercises);
  }

  void _emitAdded(Emitter<WorkoutSession> emit, List<Exercise> added) {
    final exercises = [...state.exercises, ...added];
    emit(
      state.copyWith(
        exercises: exercises,
        currentIndex: exercises.length - 1,
        status: WorkoutStatus.active,
        startedAt: state.startedAt ?? DateTime.now(),
      ),
    );
  }

  void _onRemoved(WorkoutExerciseRemoved event, Emitter<WorkoutSession> emit) {
    if (event.index < 0 || event.index >= state.exercises.length) return;
    final exercises = [...state.exercises]..removeAt(event.index);
    final nextIndex = state.currentIndex >= exercises.length
        ? exercises.isEmpty
              ? 0
              : exercises.length - 1
        : state.currentIndex;
    emit(state.copyWith(exercises: exercises, currentIndex: nextIndex));
  }

  void _onStep(WorkoutStepRequested event, Emitter<WorkoutSession> emit) {
    final target = state.currentIndex + event.delta;
    if (target < 0 || target >= state.exercises.length) return;
    emit(state.copyWith(currentIndex: target));
  }
}

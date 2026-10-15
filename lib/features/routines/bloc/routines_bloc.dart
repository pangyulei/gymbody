import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/routine_repository.dart';
import 'routines_event.dart';
import 'routines_state.dart';

/// Owns the user's saved routines.
class RoutinesBloc extends Bloc<RoutinesEvent, RoutinesState> {
  RoutinesBloc({required this._repository}) : super(const RoutinesState()) {
    on<RoutinesLoadRequested>(_onLoad);
    on<RoutineSaveRequested>(_onSave);
    on<RoutineRenamed>(_onRename);
    on<RoutineExercisesUpdated>(_onUpdateExercises);
    on<RoutineDeleted>(_onDelete);
  }

  final RoutineRepository _repository;

  void _onLoad(RoutinesLoadRequested event, Emitter<RoutinesState> emit) {
    emit(state.copyWith(status: RoutinesStatus.loading, clearError: true));
    emit(state.copyWith(status: RoutinesStatus.ready, routines: _repository.all()));
  }

  Future<void> _onSave(RoutineSaveRequested event, Emitter<RoutinesState> emit) async {
    await _repository.create(name: event.name, exerciseIds: event.exerciseIds);
    emit(state.copyWith(routines: _repository.all()));
  }

  Future<void> _onRename(RoutineRenamed event, Emitter<RoutinesState> emit) async {
    await _repository.rename(event.id, event.name);
    emit(state.copyWith(routines: _repository.all()));
  }

  Future<void> _onUpdateExercises(RoutineExercisesUpdated event, Emitter<RoutinesState> emit) async {
    await _repository.updateExercises(event.id, event.exerciseIds);
    emit(state.copyWith(routines: _repository.all()));
  }

  Future<void> _onDelete(RoutineDeleted event, Emitter<RoutinesState> emit) async {
    await _repository.delete(event.id);
    emit(state.copyWith(routines: _repository.all()));
  }
}

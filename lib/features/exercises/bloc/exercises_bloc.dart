import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/exercise_repository.dart';
import '../../../data/repositories/favorite_repository.dart';
import '../../../domain/models/exercise.dart';
import 'exercises_event.dart';
import 'exercises_state.dart';

/// Owns the exercise catalogue: loading it, filtering it and tracking the
/// user's favorites.
///
/// Provided once at the app root so the exercises tab, the workout picker and
/// the routine screens all share the same loaded dataset and favorite state.
class ExercisesBloc extends Bloc<ExercisesEvent, ExercisesState> {
  ExercisesBloc({required this._repository, required this._favorites}) : super(ExercisesState()) {
    on<ExercisesLoadRequested>(_onLoad);
    on<ExercisesSearchChanged>(
      (event, emit) => emit(state.copyWith(filter: state.filter.copyWith(query: event.query))),
    );
    on<ExercisesBodyPartToggled>(
      (event, emit) => emit(state.copyWith(filter: state.filter.toggleBodyPart(event.bodyPart))),
    );
    on<ExercisesEquipmentToggled>(
      (event, emit) => emit(state.copyWith(filter: state.filter.toggleEquipment(event.equipment))),
    );
    on<ExercisesSelectionCleared>((event, emit) => emit(state.copyWith(filter: state.filter.clearedSelection())));
    on<ExerciseFavoriteToggled>(_onFavoriteToggled);
    on<ExercisesCustomAdded>(_onReloadRequested);
    on<ExerciseDeleted>(_onDeleted);
  }

  final ExerciseRepository _repository;
  final FavoriteRepository _favorites;

  Future<void> _onLoad(ExercisesLoadRequested event, Emitter<ExercisesState> emit) async {
    emit(state.copyWith(status: ExercisesStatus.loading, clearError: true));
    try {
      final all = await _repository.loadAll();
      emit(
        state.copyWith(
          status: ExercisesStatus.ready,
          all: all,
          favoriteIds: _favorites.all(),
          bodyPartOptions: _options(all, (e) => e.bodyPart),
          equipmentOptions: _options(all, (e) => e.equipment),
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: ExercisesStatus.failure, error: 'Could not load exercises: $error'));
    }
  }

  Future<void> _onReloadRequested(ExercisesCustomAdded event, Emitter<ExercisesState> emit) async {
    try {
      final all = await _repository.loadAll();
      emit(
        state.copyWith(
          status: ExercisesStatus.ready,
          all: all,
          favoriteIds: _favorites.all(),
          bodyPartOptions: _options(all, (e) => e.bodyPart),
          equipmentOptions: _options(all, (e) => e.equipment),
        ),
      );
    } catch (error) {
      emit(state.copyWith(error: 'Could not refresh exercises: $error'));
    }
  }

  void _onFavoriteToggled(ExerciseFavoriteToggled event, Emitter<ExercisesState> emit) {
    _favorites.toggle(event.exerciseId);
    emit(state.copyWith(favoriteIds: _favorites.all()));
  }

  Future<void> _onDeleted(ExerciseDeleted event, Emitter<ExercisesState> emit) async {
    await _repository.deleteCustomExercise(event.exerciseId);
    final all = await _repository.loadAll();
    emit(
      state.copyWith(
        all: all,
        favoriteIds: _favorites.all(),
        bodyPartOptions: _options(all, (e) => e.bodyPart),
        equipmentOptions: _options(all, (e) => e.equipment),
      ),
    );
  }

  static List<String> _options(List<Exercise> exercises, String Function(Exercise) selector) {
    final values = <String>{};
    for (final exercise in exercises) {
      final value = selector(exercise).trim();
      if (value.isNotEmpty) values.add(value);
    }
    return values.toList()..sort();
  }
}

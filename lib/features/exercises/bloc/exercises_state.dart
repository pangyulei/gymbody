import 'package:equatable/equatable.dart';

import '../../../domain/exercise_filter.dart';
import '../../../domain/models/exercise.dart';

enum ExercisesStatus { initial, loading, ready, failure }

/// State of the exercise browser: the full list, the current filter and the
/// derived (visible) result.
class ExercisesState extends Equatable {
  ExercisesState({
    this.status = ExercisesStatus.initial,
    this.all = const [],
    this.favoriteIds = const {},
    this.filter = const ExerciseFilter(),
    this.bodyPartOptions = const [],
    this.equipmentOptions = const [],
    this.error,
  });

  final ExercisesStatus status;

  /// Dataset exercises followed by custom ones.
  final List<Exercise> all;

  final Set<String> favoriteIds;
  final ExerciseFilter filter;

  final List<String> bodyPartOptions;
  final List<String> equipmentOptions;
  final String? error;

  /// Filtered and sorted result. Computed lazily, once per state instance.
  late final List<Exercise> visible = filter.apply(all, favoriteIds);

  /// Lookup by id, used to resolve routine entries.
  late final Map<String, Exercise> index = {for (final exercise in all) exercise.id: exercise};

  bool get isLoading => status == ExercisesStatus.loading;
  bool get hasError => status == ExercisesStatus.failure;

  bool isFavorite(String exerciseId) => favoriteIds.contains(exerciseId);

  Exercise? byId(String exerciseId) => index[exerciseId];

  String nameFor(String exerciseId) => index[exerciseId]?.name ?? 'Unknown exercise';

  ExercisesState copyWith({
    ExercisesStatus? status,
    List<Exercise>? all,
    Set<String>? favoriteIds,
    ExerciseFilter? filter,
    List<String>? bodyPartOptions,
    List<String>? equipmentOptions,
    String? error,
    bool clearError = false,
  }) {
    return ExercisesState(
      status: status ?? this.status,
      all: all ?? this.all,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      filter: filter ?? this.filter,
      bodyPartOptions: bodyPartOptions ?? this.bodyPartOptions,
      equipmentOptions: equipmentOptions ?? this.equipmentOptions,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, all, favoriteIds, filter, bodyPartOptions, equipmentOptions, error];
}

import 'package:equatable/equatable.dart';

import 'models/exercise.dart';

/// Immutable description of how the exercise list should be narrowed and
/// ordered. Kept free of Flutter/Bloc imports so it can be unit tested
/// directly and reused by any screen that browses exercises.
///
/// Favorited exercises are always pinned to the top of the result; that is
/// part of the ordering and not a user-selectable option.
class ExerciseFilter extends Equatable {
  const ExerciseFilter({this.query = '', this.bodyParts = const {}, this.equipment = const {}});

  /// Free text query, matched case-insensitively against several fields.
  final String query;

  /// Selected body parts. Multiple selections are combined with OR.
  final Set<String> bodyParts;

  /// Selected equipment. Multiple selections are combined with OR.
  final Set<String> equipment;

  bool get isEmpty => query.trim().isEmpty && bodyParts.isEmpty && equipment.isEmpty;

  int get activeFilterCount => bodyParts.length + equipment.length;

  ExerciseFilter copyWith({String? query, Set<String>? bodyParts, Set<String>? equipment}) {
    return ExerciseFilter(
      query: query ?? this.query,
      bodyParts: bodyParts ?? this.bodyParts,
      equipment: equipment ?? this.equipment,
    );
  }

  ExerciseFilter toggleBodyPart(String value) => copyWith(bodyParts: _toggle(bodyParts, value));

  ExerciseFilter toggleEquipment(String value) => copyWith(equipment: _toggle(equipment, value));

  /// Drops the chip selections while keeping the search query.
  ExerciseFilter clearedSelection() => ExerciseFilter(query: query);

  static Set<String> _toggle(Set<String> set, String value) {
    final next = Set<String>.from(set);
    if (!next.remove(value)) next.add(value);
    return next;
  }

  /// Applies the filter and sorts the result: favorites first, then by name.
  List<Exercise> apply(List<Exercise> source, Set<String> favoriteIds) {
    final normalizedQuery = query.trim().toLowerCase();

    Iterable<Exercise> items = source;
    if (bodyParts.isNotEmpty) {
      items = items.where((e) => bodyParts.contains(e.bodyPart));
    }
    if (equipment.isNotEmpty) {
      items = items.where((e) => equipment.contains(e.equipment));
    }
    if (normalizedQuery.isNotEmpty) {
      items = items.where((e) => _matchesQuery(e, normalizedQuery));
    }

    final result = items.toList(growable: false);
    result.sort((a, b) {
      final aFavorite = favoriteIds.contains(a.id);
      final bFavorite = favoriteIds.contains(b.id);
      if (aFavorite != bFavorite) return aFavorite ? -1 : 1;
      return a.sortKey.compareTo(b.sortKey);
    });
    return result;
  }

  static bool _matchesQuery(Exercise e, String query) {
    return e.name.toLowerCase().contains(query) ||
        e.bodyPart.toLowerCase().contains(query) ||
        e.equipment.toLowerCase().contains(query) ||
        e.target.toLowerCase().contains(query) ||
        e.muscleGroup.toLowerCase().contains(query);
  }

  @override
  List<Object?> get props => [query, bodyParts, equipment];
}

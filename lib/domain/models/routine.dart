import 'package:equatable/equatable.dart';

/// A saved routine, resolved from storage into a plain model for the UI.
class Routine extends Equatable {
  const Routine({
    required this.id,
    required this.name,
    required this.exerciseIds,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;

  /// Ordered exercise ids, referencing the dataset or a custom exercise.
  final List<String> exerciseIds;

  final DateTime createdAt;
  final DateTime updatedAt;

  int get exerciseCount => exerciseIds.length;

  Routine copyWith({String? name, List<String>? exerciseIds, DateTime? updatedAt}) {
    return Routine(
      id: id,
      name: name ?? this.name,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, exerciseIds, createdAt, updatedAt];
}

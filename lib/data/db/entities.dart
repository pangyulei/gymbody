import 'package:objectbox/objectbox.dart';

/// A favorited exercise. Only the exercise id is stored so that the bundled
/// dataset stays the single source of truth and never has to be modified.
@Entity()
class FavoriteEntity {
  FavoriteEntity({required this.exerciseId, required this.addedAt});

  @Id()
  int id = 0;

  /// Id of the exercise in the read-only dataset or `custom:<objectId>`.
  @Unique()
  String exerciseId;

  /// Milliseconds since epoch, used to keep a stable, recent-first order.
  int addedAt;
}

/// A user created exercise. Binary files (poster/gif) are copied into the
/// application documents directory and only their paths are persisted here.
@Entity()
class CustomExerciseEntity {
  CustomExerciseEntity({
    required this.name,
    required this.bodyPart,
    required this.equipment,
    required this.instructions,
    required this.createdAt,
    this.target = '',
    this.muscleGroup = '',
    this.secondaryMuscles = const [],
    this.instructionSteps = const [],
    this.posterPath,
    this.gifPath,
  });

  @Id()
  int id = 0;

  String name;
  String bodyPart;
  String equipment;
  String target;
  String muscleGroup;
  List<String> secondaryMuscles;

  /// Free-form instructions, one step per entry for consistent rendering.
  List<String> instructionSteps;
  String instructions;

  /// Absolute path to the poster image (png) inside app documents, if any.
  String? posterPath;

  /// Absolute path to the instruction animation (gif) inside app documents.
  String? gifPath;

  int createdAt;
}

/// A saved routine: an ordered list of exercise ids.
///
/// Ids reference either the dataset or a custom exercise (`custom:<objectId>`).
/// Resolving ids at read time keeps this entity free of relations/joins.
@Entity()
class RoutineEntity {
  RoutineEntity({required this.name, required this.createdAt, required this.updatedAt, this.exerciseIds = const []});

  @Id()
  int id = 0;

  String name;
  int createdAt;
  int updatedAt;
  List<String> exerciseIds;
}

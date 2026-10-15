import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/constants.dart';
import '../../domain/models/exercise.dart';
import '../../objectbox.g.dart';
import '../db/entities.dart';
import '../sources/exercise_asset_source.dart';

/// Single entry point for exercises, whether they come from the read-only
/// dataset or were created by the user.
class ExerciseRepository {
  ExerciseRepository({required this._assetSource, required this._customBox, required this._documentsDirectory});

  final ExerciseAssetSource _assetSource;
  final Box<CustomExerciseEntity> _customBox;
  final Directory _documentsDirectory;

  List<Exercise>? _datasetCache;

  /// Loads (and caches) the bundled dataset.
  Future<List<Exercise>> loadDataset() async {
    return _datasetCache ??= await _assetSource.load();
  }

  /// Custom exercises, newest first.
  List<Exercise> customExercises() {
    final entities = _customBox.getAll()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entities.map(_toExercise).toList(growable: false);
  }

  /// The dataset followed by the user's custom exercises.
  Future<List<Exercise>> loadAll() async {
    final dataset = await loadDataset();
    return [...dataset, ...customExercises()];
  }

  /// Creates a custom exercise, copying the picked media into the app
  /// documents directory so the originals can be deleted by the user.
  Future<Exercise> createCustomExercise({
    required String name,
    required String bodyPart,
    required String equipment,
    String target = '',
    String muscleGroup = '',
    String instructions = '',
    List<String> instructionSteps = const [],
    String? posterSourcePath,
    String? gifSourcePath,
  }) async {
    final posterPath = await _importMedia(posterSourcePath, 'poster');
    final gifPath = await _importMedia(gifSourcePath, 'animation');

    final entity = CustomExerciseEntity(
      name: name.trim(),
      bodyPart: bodyPart,
      equipment: equipment,
      target: target,
      muscleGroup: muscleGroup,
      instructions: instructions,
      instructionSteps: instructionSteps,
      posterPath: posterPath,
      gifPath: gifPath,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final objectId = _customBox.put(entity);
    return _toExercise(entity..id = objectId);
  }

  /// Deletes a custom exercise together with its imported media.
  ///
  /// Only custom exercises can be deleted; dataset entries are ignored.
  Future<bool> deleteCustomExercise(String exerciseId) async {
    final objectId = AppConstants.customObjectId(exerciseId);
    if (objectId == null) return false;

    final entity = _customBox.get(objectId);
    if (entity == null) return false;

    for (final path in [entity.posterPath, entity.gifPath]) {
      if (path == null || path.isEmpty) continue;
      final file = File(path);
      if (file.existsSync()) {
        try {
          await file.delete();
        } on FileSystemException {
          // The record is still removed below; a stale file is harmless.
        }
      }
    }

    _customBox.remove(objectId);
    return true;
  }

  Future<String?> _importMedia(String? sourcePath, String kind) async {
    if (sourcePath == null || sourcePath.isEmpty) return null;
    final source = File(sourcePath);
    if (!source.existsSync()) return null;

    final dir = Directory(p.join(_documentsDirectory.path, AppConstants.customMediaDir));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final extension = p.extension(sourcePath).toLowerCase();
    final fileName = '${kind}_${DateTime.now().microsecondsSinceEpoch}$extension';
    final target = File(p.join(dir.path, fileName));
    await source.copy(target.path);
    return target.path;
  }

  Exercise _toExercise(CustomExerciseEntity entity) {
    return Exercise(
      id: AppConstants.customId(entity.id),
      name: entity.name,
      bodyPart: entity.bodyPart,
      equipment: entity.equipment,
      target: entity.target,
      muscleGroup: entity.muscleGroup,
      secondaryMuscles: entity.secondaryMuscles,
      instructions: entity.instructions,
      instructionSteps: entity.instructionSteps,
      posterPath: entity.posterPath,
      gifPath: entity.gifPath,
      source: ExerciseSource.custom,
    );
  }
}

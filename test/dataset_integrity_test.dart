import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymbody/core/constants.dart';
import 'package:gymbody/data/sources/exercise_asset_source.dart';

/// Reads the real bundled dataset to make sure it stays consistent with the
/// media files on disk. This guards the read-only dataset contract: the app
/// never rewrites it, so it must be complete as shipped.
void main() {
  test('the bundled dataset parses and every referenced media file exists', () {
    final dataset = File(AppConstants.datasetAssetPath);
    expect(dataset.existsSync(), isTrue, reason: '${AppConstants.datasetAssetPath} is missing');

    final exercises = parseExerciseDataset(dataset.readAsStringSync());
    expect(exercises, isNotEmpty);
    expect(exercises.map((e) => e.id).toSet(), hasLength(exercises.length), reason: 'exercise ids must be unique');

    final missing = <String>[];
    for (final exercise in exercises) {
      for (final path in [exercise.posterPath, exercise.gifPath]) {
        if (path == null) continue;
        if (!File(path).existsSync()) missing.add('${exercise.id} -> $path');
      }
    }

    expect(
      missing,
      isEmpty,
      reason:
          '${missing.length} referenced media files are missing, '
          'for example: ${missing.take(5).join(', ')}',
    );
  });
}

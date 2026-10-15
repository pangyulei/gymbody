import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;

import '../../core/constants.dart';
import '../../domain/models/exercise.dart';

/// Reads the bundled, read-only exercise dataset.
///
/// The file is never modified: it is loaded from assets and parsed off the UI
/// isolate so the ~17 MB payload does not jank the first frame.
class ExerciseAssetSource {
  const ExerciseAssetSource({this.assetPath = AppConstants.datasetAssetPath, this.language = AppConstants.language});

  final String assetPath;
  final String language;

  Future<List<Exercise>> load() async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    return compute(_decodeDataset, bytes);
  }
}

/// Isolate entry point. Must be a top level function for [compute].
List<Exercise> _decodeDataset(Uint8List bytes) {
  return parseExerciseDataset(utf8.decode(bytes));
}

/// Parses the raw dataset JSON into [Exercise]s.
///
/// Kept public and side-effect free so it can be unit tested without Flutter
/// bindings or asset loading.
List<Exercise> parseExerciseDataset(String jsonString, {String language = AppConstants.language}) {
  // Tolerate a UTF-8 byte order mark, which would otherwise break jsonDecode.
  final normalized = jsonString.startsWith('\uFEFF') ? jsonString.substring(1) : jsonString;

  final decoded = jsonDecode(normalized);
  if (decoded is! List) {
    throw const FormatException('Exercise dataset must be a JSON array');
  }

  final exercises = <Exercise>[];
  for (final entry in decoded) {
    if (entry is! Map) continue;
    final exercise = Exercise.fromDataset(entry.cast<String, dynamic>(), language: language);
    if (exercise.id.isEmpty || exercise.name.isEmpty) continue;
    exercises.add(exercise);
  }
  return exercises;
}

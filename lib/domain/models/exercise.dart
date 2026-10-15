import 'package:equatable/equatable.dart';

import '../../core/constants.dart';

/// Whether an exercise comes from the bundled dataset or was created by the
/// user. This decides where its media is loaded from.
enum ExerciseSource { dataset, custom }

/// The unified exercise model used everywhere in the UI.
///
/// Dataset exercises are derived from `assets/exercises/exercises.json`; custom
/// ones are built from a persisted [ExerciseSource.custom] record and point at
/// files inside the application documents directory.
class Exercise extends Equatable {
  const Exercise({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.equipment,
    this.target = '',
    this.muscleGroup = '',
    this.secondaryMuscles = const [],
    this.instructions = '',
    this.instructionSteps = const [],
    this.posterPath,
    this.gifPath,
    this.source = ExerciseSource.dataset,
  });

  /// Dataset id (e.g. `0001`) or `custom:<objectId>`.
  final String id;
  final String name;
  final String bodyPart;
  final String equipment;
  final String target;
  final String muscleGroup;
  final List<String> secondaryMuscles;
  final String instructions;
  final List<String> instructionSteps;

  /// Asset path (dataset) or absolute file path (custom) to the poster image.
  final String? posterPath;

  /// Asset path (dataset) or absolute file path (custom) to the gif/animation.
  final String? gifPath;

  final ExerciseSource source;

  bool get isCustom => source == ExerciseSource.custom;
  bool get hasPoster => posterPath != null && posterPath!.isNotEmpty;
  bool get hasGif => gifPath != null && gifPath!.isNotEmpty;

  /// Longest name of an exercise, used for stable alphabetical sorting.
  String get sortKey => name.toLowerCase();

  /// Builds an exercise from a single entry of the bundled dataset.
  factory Exercise.fromDataset(Map<String, dynamic> json, {String language = AppConstants.language}) {
    final instructionsMap = _asStringMap(json['instructions']);
    final stepsMap = _asStringMap(json['instruction_steps']);

    final steps = _localizedList(stepsMap, language);
    var instructions = _localizedString(instructionsMap, language);
    if (instructions.isEmpty) {
      instructions = steps.join(' ');
    }

    return Exercise(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString().trim(),
      bodyPart: (json['body_part'] ?? '').toString(),
      equipment: (json['equipment'] ?? '').toString(),
      target: (json['target'] ?? '').toString(),
      muscleGroup: (json['muscle_group'] ?? '').toString(),
      secondaryMuscles: _asStringList(json['secondary_muscles']),
      instructions: instructions,
      instructionSteps: steps,
      posterPath: _resolveDatasetMedia(json['image']),
      gifPath: _resolveDatasetMedia(json['gif_url']),
      source: ExerciseSource.dataset,
    );
  }

  static String? _resolveDatasetMedia(Object? value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    return '${AppConstants.datasetAssetPrefix}$raw';
  }

  static Map<String, dynamic> _asStringMap(Object? value) {
    if (value is Map) return value.cast<String, dynamic>();
    return const {};
  }

  static List<String> _asStringList(Object? value) {
    if (value is List) {
      return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList(growable: false);
    }
    return const [];
  }

  static String _localizedString(Map<String, dynamic> map, String language) {
    final preferred = map[language];
    if (preferred is String && preferred.trim().isNotEmpty) return preferred;
    for (final value in map.values) {
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return '';
  }

  static List<String> _localizedList(Map<String, dynamic> map, String language) {
    final preferred = map[language];
    if (preferred is List) {
      final list = _asStringList(preferred);
      if (list.isNotEmpty) return list;
    }
    for (final value in map.values) {
      if (value is List) {
        final list = _asStringList(value);
        if (list.isNotEmpty) return list;
      }
    }
    return const [];
  }

  @override
  List<Object?> get props => [id, name, bodyPart, equipment, posterPath, gifPath, source];
}

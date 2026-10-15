/// Static configuration shared across the app.
class AppConstants {
  const AppConstants._();

  /// Bundled, read-only exercise dataset. It is never written to at runtime.
  static const String datasetAssetPath = 'assets/exercises/exercises.json';

  /// Every media path inside the dataset is relative to this folder.
  static const String datasetAssetPrefix = 'assets/exercises/';

  /// Prefix used to build ids for user created exercises, e.g. `custom:7`.
  static const String customIdPrefix = 'custom:';

  /// Sub folder inside the app documents directory that holds custom media.
  static const String customMediaDir = 'custom_exercises';

  /// ObjectBox database folder inside the app documents directory.
  static const String databaseDir = 'gymbody-db';

  /// Language used when reading the multi language dataset.
  static const String language = 'en';

  static String customId(int objectId) => '$customIdPrefix$objectId';

  static bool isCustomId(String id) => id.startsWith(customIdPrefix);

  /// Returns the numeric ObjectBox id for a `custom:<id>` exercise id.
  static int? customObjectId(String id) => isCustomId(id) ? int.tryParse(id.substring(customIdPrefix.length)) : null;
}

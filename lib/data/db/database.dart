import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';
import '../../objectbox.g.dart';
import 'entities.dart';

/// Owns the ObjectBox [Store] and exposes the boxes used by the repositories.
class AppDatabase {
  AppDatabase._(this.store);

  final Store store;

  Box<FavoriteEntity> get favorites => store.box<FavoriteEntity>();

  Box<CustomExerciseEntity> get customExercises => store.box<CustomExerciseEntity>();

  Box<RoutineEntity> get routines => store.box<RoutineEntity>();

  /// Opens (creating it if needed) the ObjectBox database used by the app.
  static Future<AppDatabase> open({String? directory}) async {
    final dir = directory ?? await _defaultDirectory();
    final store = await openStore(directory: dir);
    return AppDatabase._(store);
  }

  static Future<String> _defaultDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(documents.path, AppConstants.databaseDir));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir.path;
  }

  void close() => store.close();
}

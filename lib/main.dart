import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/app_theme.dart';
import 'data/db/database.dart';
import 'data/repositories/exercise_repository.dart';
import 'data/repositories/favorite_repository.dart';
import 'data/repositories/routine_repository.dart';
import 'data/sources/exercise_asset_source.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final database = await AppDatabase.open();
    final documents = await getApplicationDocumentsDirectory();

    runApp(
      GymBodyApp(
        exerciseRepository: ExerciseRepository(
          assetSource: const ExerciseAssetSource(),
          customBox: database.customExercises,
          documentsDirectory: documents,
        ),
        favoriteRepository: FavoriteRepository(database.favorites),
        routineRepository: RoutineRepository(database.routines),
      ),
    );
  } catch (error) {
    runApp(StartupFailureApp(error: error));
  }
}

/// Shown when the local database cannot be opened, so the user gets an
/// actionable message instead of a blank window.
class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text('GymBody could not start', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('$error', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

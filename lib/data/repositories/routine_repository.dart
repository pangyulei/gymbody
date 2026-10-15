import '../../domain/models/routine.dart';
import '../../objectbox.g.dart';
import '../db/entities.dart';

/// Persists the user's routines as ordered lists of exercise ids.
class RoutineRepository {
  RoutineRepository(this._box);

  final Box<RoutineEntity> _box;

  /// All routines, most recently updated first.
  List<Routine> all() {
    final routines = _box.getAll().map(_toRoutine).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return routines;
  }

  Routine? get(int id) {
    final entity = _box.get(id);
    return entity == null ? null : _toRoutine(entity);
  }

  Future<Routine> create({required String name, required List<String> exerciseIds}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final entity = RoutineEntity(
      name: _normalizeName(name),
      createdAt: now,
      updatedAt: now,
      exerciseIds: List<String>.of(exerciseIds),
    );
    final id = _box.put(entity);
    return _toRoutine(entity..id = id);
  }

  Future<Routine?> rename(int id, String name) async {
    final entity = _box.get(id);
    if (entity == null) return null;
    entity
      ..name = _normalizeName(name)
      ..updatedAt = DateTime.now().millisecondsSinceEpoch;
    _box.put(entity);
    return _toRoutine(entity);
  }

  Future<Routine?> updateExercises(int id, List<String> exerciseIds) async {
    final entity = _box.get(id);
    if (entity == null) return null;
    entity
      ..exerciseIds = List<String>.of(exerciseIds)
      ..updatedAt = DateTime.now().millisecondsSinceEpoch;
    _box.put(entity);
    return _toRoutine(entity);
  }

  Future<bool> delete(int id) async => _box.remove(id);

  static String _normalizeName(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? 'Untitled routine' : trimmed;
  }

  Routine _toRoutine(RoutineEntity entity) {
    return Routine(
      id: entity.id,
      name: entity.name,
      exerciseIds: List<String>.unmodifiable(entity.exerciseIds),
      createdAt: DateTime.fromMillisecondsSinceEpoch(entity.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(entity.updatedAt),
    );
  }
}

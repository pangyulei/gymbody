import '../../objectbox.g.dart';
import '../db/entities.dart';

/// Stores which exercises the user marked as favorite.
///
/// Only exercise ids are persisted; the bundled dataset itself is untouched.
class FavoriteRepository {
  FavoriteRepository(this._box);

  final Box<FavoriteEntity> _box;

  /// All favorite exercise ids.
  Set<String> all() {
    return _box.getAll().map((e) => e.exerciseId).toSet();
  }

  bool isFavorite(String exerciseId) {
    final query = _box.query(FavoriteEntity_.exerciseId.equals(exerciseId)).build();
    try {
      return query.findFirst() != null;
    } finally {
      query.close();
    }
  }

  /// Adds or removes the favorite and returns the new favorite state.
  bool toggle(String exerciseId) {
    final query = _box.query(FavoriteEntity_.exerciseId.equals(exerciseId)).build();
    FavoriteEntity? existing;
    try {
      existing = query.findFirst();
    } finally {
      query.close();
    }

    if (existing != null) {
      _box.remove(existing.id);
      return false;
    }

    _box.put(FavoriteEntity(exerciseId: exerciseId, addedAt: DateTime.now().millisecondsSinceEpoch));
    return true;
  }
}

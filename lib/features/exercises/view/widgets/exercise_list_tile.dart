import 'package:flutter/material.dart';

import '../../../../core/widgets/exercise_image.dart';
import '../../../../domain/models/exercise.dart';

/// Compact row used in the exercise lists: poster, name, tags and a favorite
/// toggle on the trailing edge.
class ExerciseListTile extends StatelessWidget {
  const ExerciseListTile({
    super.key,
    required this.exercise,
    required this.isFavorite,
    required this.onFavoriteToggled,
    this.onTap,
    this.trailing,
  });

  final Exercise exercise;
  final bool isFavorite;
  final VoidCallback onFavoriteToggled;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      if (exercise.bodyPart.isNotEmpty) exercise.bodyPart,
      if (exercise.equipment.isNotEmpty) exercise.equipment,
    ].join(' · ');

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 56,
          height: 56,
          child: ExerciseImage(posterPath: exercise.posterPath, gifPath: exercise.gifPath),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(exercise.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
          ),
          if (exercise.isCustom)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(Icons.person_outline, size: 16, color: theme.colorScheme.primary),
            ),
        ],
      ),
      subtitle: subtitle.isEmpty ? null : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: isFavorite ? 'Remove from favorites' : 'Mark as favorite',
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? theme.colorScheme.error : null,
            ),
            onPressed: onFavoriteToggled,
          ),
          ?trailing,
        ],
      ),
    );
  }
}

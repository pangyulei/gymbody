import 'package:flutter/material.dart';

import '../../../../domain/exercise_filter.dart';
import 'exercise_filter_sheet.dart';

/// Search field plus the fast filters (body part and equipment).
///
/// Favorites are always pinned to the top of the list, so there is no
/// favorites toggle here.
class ExerciseFilterBar extends StatelessWidget {
  const ExerciseFilterBar({
    super.key,
    required this.searchController,
    required this.filter,
    required this.bodyPartOptions,
    required this.equipmentOptions,
    required this.resultCount,
    required this.totalCount,
    required this.onQueryChanged,
    required this.onBodyPartToggled,
    required this.onEquipmentToggled,
    required this.onClear,
  });

  final TextEditingController searchController;
  final ExerciseFilter filter;
  final List<String> bodyPartOptions;
  final List<String> equipmentOptions;
  final int resultCount;
  final int totalCount;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onBodyPartToggled;
  final ValueChanged<String> onEquipmentToggled;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search exercises',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: searchController,
                builder: (context, value, _) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      searchController.clear();
                      onQueryChanged('');
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterButton(
                  icon: Icons.accessibility_new,
                  label: 'Body part',
                  count: filter.bodyParts.length,
                  onPressed: () => ExerciseFilterSheet.show(
                    context,
                    title: 'Body part',
                    options: bodyPartOptions,
                    selected: filter.bodyParts,
                    onToggle: onBodyPartToggled,
                    onClear: () {
                      for (final value in filter.bodyParts.toList()) {
                        onBodyPartToggled(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                _FilterButton(
                  icon: Icons.fitness_center,
                  label: 'Equipment',
                  count: filter.equipment.length,
                  onPressed: () => ExerciseFilterSheet.show(
                    context,
                    title: 'Equipment',
                    options: equipmentOptions,
                    selected: filter.equipment,
                    onToggle: onEquipmentToggled,
                    onClear: () {
                      for (final value in filter.equipment.toList()) {
                        onEquipmentToggled(value);
                      }
                    },
                  ),
                ),
                if (filter.activeFilterCount > 0 || filter.query.trim().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.filter_alt_off, size: 18),
                    label: const Text('Clear'),
                    // The parent owns the search controller, so it is responsible
                    // for clearing both the field and the applied query.
                    onPressed: onClear,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$resultCount of $totalCount exercises',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.icon, required this.label, required this.count, required this.onPressed});

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final selected = count > 0;
    final scheme = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(selected ? '$label ($count)' : label),
      backgroundColor: selected ? scheme.secondaryContainer : null,
      onPressed: onPressed,
    );
  }
}

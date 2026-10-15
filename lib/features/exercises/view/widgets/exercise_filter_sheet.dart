import 'package:flutter/material.dart';

/// Multi-select bottom sheet for a single filter dimension (body part or
/// equipment). Toggling a chip applies immediately via [onToggle] so filtering
/// feels instant while the sheet stays open.
class ExerciseFilterSheet extends StatefulWidget {
  const ExerciseFilterSheet({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.onClear,
  });

  final String title;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<String> options,
    required Set<String> selected,
    required ValueChanged<String> onToggle,
    required VoidCallback onClear,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) =>
          ExerciseFilterSheet(title: title, options: options, selected: selected, onToggle: onToggle, onClear: onClear),
    );
  }

  @override
  State<ExerciseFilterSheet> createState() => _ExerciseFilterSheetState();
}

class _ExerciseFilterSheetState extends State<ExerciseFilterSheet> {
  late final Set<String> _selected = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(child: Text(widget.title, style: theme.textTheme.titleMedium)),
                  if (_selected.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(_selected.clear);
                        widget.onClear();
                      },
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final option in widget.options)
                      FilterChip(
                        label: Text(option),
                        selected: _selected.contains(option),
                        onSelected: (_) {
                          setState(() {
                            if (!_selected.remove(option)) _selected.add(option);
                          });
                          widget.onToggle(option);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Dialog used both when renaming a routine from the list and from its detail
/// page. Pops with the new name, or `null` when cancelled.
class RenameRoutineDialog extends StatefulWidget {
  const RenameRoutineDialog({super.key, required this.initialName});

  final String initialName;

  static Future<String?> show(BuildContext context, String initialName) {
    return showDialog<String>(
      context: context,
      builder: (_) => RenameRoutineDialog(initialName: initialName),
    );
  }

  @override
  State<RenameRoutineDialog> createState() => _RenameRoutineDialogState();
}

class _RenameRoutineDialogState extends State<RenameRoutineDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename routine'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: 'Routine name'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

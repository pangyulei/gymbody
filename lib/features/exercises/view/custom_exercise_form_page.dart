import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/widgets/exercise_image.dart';
import '../../../data/repositories/exercise_repository.dart';
import '../../custom_exercise/bloc/custom_exercise_form_cubit.dart';
import '../bloc/exercises_bloc.dart';

/// Form for creating a custom exercise.
///
/// The picked PNG poster and GIF instruction are only referenced here; they are
/// copied into the application documents directory when the form is saved.
class CustomExerciseFormPage extends StatelessWidget {
  const CustomExerciseFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CustomExerciseFormCubit(repository: context.read<ExerciseRepository>()),
      child: const _CustomExerciseFormView(),
    );
  }
}

class _CustomExerciseFormView extends StatefulWidget {
  const _CustomExerciseFormView();

  @override
  State<_CustomExerciseFormView> createState() => _CustomExerciseFormViewState();
}

class _CustomExerciseFormViewState extends State<_CustomExerciseFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bodyPartController = TextEditingController();
  final _equipmentController = TextEditingController();
  final _targetController = TextEditingController();
  final _muscleGroupController = TextEditingController();
  final _instructionsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _bodyPartController.dispose();
    _equipmentController.dispose();
    _targetController.dispose();
    _muscleGroupController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile({required bool poster}) async {
    final cubit = context.read<CustomExerciseFormCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final extension = poster ? 'png' : 'gif';

    final picked = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: [extension]);
    if (picked == null) return;

    if ((picked.extension ?? '').toLowerCase() != extension) {
      messenger.showSnackBar(SnackBar(content: Text('Please choose a .$extension file')));
      return;
    }

    // Android normally hands back a real path; when it only exposes a URI the
    // bytes are staged into a temporary file first.
    var localPath = picked.path;
    if (localPath == null || localPath.isEmpty) {
      localPath = await _stageToTempFile(picked.readAsByteStream(), extension);
    }
    if (localPath == null) {
      messenger.showSnackBar(SnackBar(content: Text('Could not read the selected .$extension file')));
      return;
    }

    if (poster) {
      cubit.setPoster(localPath);
    } else {
      cubit.setGif(localPath);
    }
  }

  static Future<String?> _stageToTempFile(Stream<List<int>> bytes, String extension) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final target = File(p.join(tempDir.path, 'gymbody_pick_${DateTime.now().microsecondsSinceEpoch}.$extension'));
      final sink = target.openWrite();
      await sink.addStream(bytes);
      await sink.close();
      return target.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<CustomExerciseFormCubit>();
    final navigator = Navigator.of(context);
    final exercise = await cubit.submit();
    if (exercise != null) navigator.pop(exercise);
  }

  @override
  Widget build(BuildContext context) {
    final options = context.watch<ExercisesBloc>().state;

    return BlocListener<CustomExerciseFormCubit, CustomExerciseFormState>(
      listenWhen: (previous, current) => current.error != null && previous.error != current.error,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error ?? 'Something went wrong')));
      },
      child: BlocBuilder<CustomExerciseFormCubit, CustomExerciseFormState>(
        builder: (context, state) {
          final cubit = context.read<CustomExerciseFormCubit>();

          return Scaffold(
            appBar: AppBar(title: const Text('New exercise')),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _MediaPicker(
                    label: 'Poster',
                    hint: 'PNG image',
                    path: state.posterPath,
                    isAnimation: false,
                    onPick: () => _pickFile(poster: true),
                    onClear: () => cubit.setPoster(null),
                  ),
                  const SizedBox(height: 16),
                  _MediaPicker(
                    label: 'Instruction',
                    hint: 'GIF animation',
                    path: state.gifPath,
                    isAnimation: true,
                    onPick: () => _pickFile(poster: false),
                    onClear: () => cubit.setGif(null),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Name *', hintText: 'e.g. Incline dumbbell press'),
                    onChanged: cubit.setName,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Give the exercise a name' : null,
                  ),
                  const SizedBox(height: 16),
                  _OptionField(
                    label: 'Body part *',
                    controller: _bodyPartController,
                    options: options.bodyPartOptions,
                    onChanged: cubit.setBodyPart,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Choose a body part' : null,
                  ),
                  const SizedBox(height: 16),
                  _OptionField(
                    label: 'Equipment *',
                    controller: _equipmentController,
                    options: options.equipmentOptions,
                    onChanged: cubit.setEquipment,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Choose the equipment' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _targetController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Target muscle', hintText: 'e.g. pectorals'),
                    onChanged: cubit.setTarget,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _muscleGroupController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Muscle group', hintText: 'e.g. chest'),
                    onChanged: cubit.setMuscleGroup,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _instructionsController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Instructions',
                      helperText: 'One step per line',
                      alignLabelWithHint: true,
                    ),
                    onChanged: cubit.setInstructions,
                  ),
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: state.isSaving ? null : _submit,
                icon: state.isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(state.isSaving ? 'Saving…' : 'Save exercise'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MediaPicker extends StatelessWidget {
  const _MediaPicker({
    required this.label,
    required this.hint,
    required this.path,
    required this.isAnimation,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final String hint;
  final String? path;
  final bool isAnimation;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFile = path != null && path!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label ($hint)', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: hasFile
                ? ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: ExerciseImage(
                      posterPath: isAnimation ? null : path,
                      gifPath: isAnimation ? path : null,
                      animate: isAnimation,
                      fit: BoxFit.contain,
                      icon: Icons.fitness_center,
                    ),
                  )
                : Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isAnimation ? Icons.gif_box_outlined : Icons.image_outlined,
                          size: 32,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 4),
                        Text('No $hint selected', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.upload_file),
              label: Text(hasFile ? 'Replace' : 'Pick $hint'),
            ),
            const SizedBox(width: 8),
            if (hasFile)
              TextButton.icon(onPressed: onClear, icon: const Icon(Icons.delete_outline), label: const Text('Remove')),
          ],
        ),
      ],
    );
  }
}

class _OptionField extends StatelessWidget {
  const _OptionField({
    required this.label,
    required this.controller,
    required this.options,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: label),
          validator: validator,
          onChanged: onChanged,
        ),
        if (options.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final option in options)
                ActionChip(
                  label: Text(option),
                  onPressed: () {
                    controller.text = option;
                    onChanged(option);
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}

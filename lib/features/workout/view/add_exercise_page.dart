import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/exercise_filter.dart';
import '../../../domain/models/exercise.dart';
import '../../exercises/bloc/exercises_bloc.dart';
import '../../exercises/bloc/exercises_event.dart';
import '../../exercises/bloc/exercises_state.dart';
import '../../exercises/view/custom_exercise_form_page.dart';
import '../../exercises/view/widgets/exercise_filter_bar.dart';
import '../../exercises/view/widgets/exercise_list_tile.dart';

/// Multi-select exercise picker used both to fill a workout and to fill a
/// routine. Pops with the chosen exercises (or `null` when cancelled).
class AddExercisePage extends StatefulWidget {
  const AddExercisePage({super.key, this.title = 'Add exercises'});

  final String title;

  @override
  State<AddExercisePage> createState() => _AddExercisePageState();
}

class _AddExercisePageState extends State<AddExercisePage> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Exercise> _selected = {};

  ExerciseFilter _filter = const ExerciseFilter();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _filter = _filter.copyWith(query: value));
    });
  }

  /// Clears the search field, any pending debounce and every filter while
  /// keeping the favorites-first preference.
  void _clearAll() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _filter = const ExerciseFilter());
  }

  void _toggleSelection(Exercise exercise) {
    setState(() {
      if (_selected.remove(exercise.id) == null) {
        _selected[exercise.id] = exercise;
      }
    });
  }

  Future<void> _createCustom() async {
    final bloc = context.read<ExercisesBloc>();
    final messenger = ScaffoldMessenger.of(context);

    final created = await Navigator.of(context)
        .push<Exercise>(MaterialPageRoute(builder: (_) => const CustomExerciseFormPage()));
    if (created == null) return;

    bloc.add(const ExercisesCustomAdded());
    setState(() => _selected[created.id] = created);
    messenger.showSnackBar(SnackBar(content: Text('"${created.name}" created and selected')));
  }

  void _confirm() {
    Navigator.of(context).pop(_selected.values.toList(growable: false));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExercisesBloc, ExercisesState>(
      builder: (context, state) {
        final visible = _filter.apply(state.all, state.favoriteIds);

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              IconButton(
                tooltip: 'Create custom exercise',
                icon: const Icon(Icons.add_box_outlined),
                onPressed: _createCustom,
              ),
            ],
          ),
          body: Column(
            children: [
              ExerciseFilterBar(
                searchController: _searchController,
                filter: _filter,
                bodyPartOptions: state.bodyPartOptions,
                equipmentOptions: state.equipmentOptions,
                resultCount: visible.length,
                totalCount: state.all.length,
                onQueryChanged: _onQueryChanged,
                onBodyPartToggled: (value) => setState(() => _filter = _filter.toggleBodyPart(value)),
                onEquipmentToggled: (value) => setState(() => _filter = _filter.toggleEquipment(value)),
                onClear: _clearAll,
              ),
              Expanded(
                child: state.all.isEmpty && state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 32),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final exercise = visible[index];
                          return ExerciseListTile(
                            exercise: exercise,
                            isFavorite: state.isFavorite(exercise.id),
                            onFavoriteToggled: () =>
                                context.read<ExercisesBloc>().add(ExerciseFavoriteToggled(exercise.id)),
                            onTap: () => _toggleSelection(exercise),
                            trailing: Checkbox(
                              value: _selected.containsKey(exercise.id),
                              onChanged: (_) => _toggleSelection(exercise),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _selected.isEmpty ? null : _confirm,
              icon: const Icon(Icons.check),
              label: Text(
                _selected.isEmpty
                    ? 'Select exercises'
                    : 'Add ${_selected.length} exercise${_selected.length == 1 ? '' : 's'}',
              ),
            ),
          ),
        );
      },
    );
  }
}

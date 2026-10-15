import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/exercise.dart';
import '../bloc/exercises_bloc.dart';
import '../bloc/exercises_event.dart';
import '../bloc/exercises_state.dart';
import 'custom_exercise_form_page.dart';
import 'exercise_detail_page.dart';
import 'widgets/exercise_filter_bar.dart';
import 'widgets/exercise_list_tile.dart';

/// Tab 1: browse, search, filter and favorite exercises.
class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Small debounce keeps typing smooth on the ~1300 entry dataset.
  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      context.read<ExercisesBloc>().add(ExercisesSearchChanged(value));
    });
  }

  /// Clears the search field, any pending debounce and every filter.
  void _clearAll() {
    _debounce?.cancel();
    _searchController.clear();
    final bloc = context.read<ExercisesBloc>();
    bloc
      ..add(const ExercisesSearchChanged(''))
      ..add(const ExercisesSelectionCleared());
  }

  Future<void> _openCustomForm() async {
    final bloc = context.read<ExercisesBloc>();
    final messenger = ScaffoldMessenger.of(context);

    final created = await Navigator.of(context)
        .push<Exercise>(MaterialPageRoute(builder: (_) => const CustomExerciseFormPage()));
    if (created == null) return;

    bloc.add(const ExercisesCustomAdded());
    messenger.showSnackBar(SnackBar(content: Text('"${created.name}" was added')));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExercisesBloc, ExercisesState>(
      listenWhen: (previous, current) => current.hasError && previous.error != current.error,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error ?? 'Something went wrong')));
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Exercises')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCustomForm,
            icon: const Icon(Icons.add),
            label: const Text('Custom'),
          ),
          body: Column(
            children: [
              ExerciseFilterBar(
                searchController: _searchController,
                filter: state.filter,
                bodyPartOptions: state.bodyPartOptions,
                equipmentOptions: state.equipmentOptions,
                resultCount: state.visible.length,
                totalCount: state.all.length,
                onQueryChanged: _onQueryChanged,
                onBodyPartToggled: (value) => context.read<ExercisesBloc>().add(ExercisesBodyPartToggled(value)),
                onEquipmentToggled: (value) => context.read<ExercisesBloc>().add(ExercisesEquipmentToggled(value)),
                onClear: _clearAll,
              ),
              Expanded(child: _buildList(state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(ExercisesState state) {
    if (state.all.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.all.isEmpty && state.hasError) {
      return _EmptyMessage(
        icon: Icons.error_outline,
        title: 'Could not load exercises',
        message: state.error ?? '',
        action: FilledButton(
          onPressed: () => context.read<ExercisesBloc>().add(const ExercisesLoadRequested()),
          child: const Text('Retry'),
        ),
      );
    }
    if (state.visible.isEmpty) {
      return const _EmptyMessage(
        icon: Icons.search_off,
        title: 'No exercises match',
        message: 'Try removing a filter or searching for something else.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: state.visible.length,
      itemBuilder: (context, index) {
        final exercise = state.visible[index];
        return ExerciseListTile(
          exercise: exercise,
          isFavorite: state.isFavorite(exercise.id),
          onFavoriteToggled: () => context.read<ExercisesBloc>().add(ExerciseFavoriteToggled(exercise.id)),
          onTap: () =>
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExerciseDetailPage(exercise: exercise))),
        );
      },
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.icon, required this.title, required this.message, this.action});

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

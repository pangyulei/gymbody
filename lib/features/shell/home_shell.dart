import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/workout_session.dart';
import '../exercises/view/exercises_page.dart';
import '../routines/view/routines_page.dart';
import '../workout/bloc/workout_bloc.dart';
import '../workout/view/workout_page.dart';
import 'home_tab_scope.dart';

/// Bottom navigation shell hosting the three main tabs.
///
/// Uses an [IndexedStack] so each tab keeps its scroll position and the draft
/// workout is never lost when switching tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HomeTabScope(
        selectTab: (index) => setState(() => _index = index),
        child: IndexedStack(index: _index, children: const [ExercisesPage(), WorkoutPage(), RoutinesPage()]),
      ),
      bottomNavigationBar: BlocBuilder<WorkoutBloc, WorkoutSession>(
        builder: (context, session) {
          final active = session.status == WorkoutStatus.active;
          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (index) => setState(() => _index = index),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.fitness_center_outlined),
                selectedIcon: Icon(Icons.fitness_center),
                label: 'Exercises',
              ),
              NavigationDestination(
                icon: active
                    ? Badge(label: Text('${session.exercises.length}'), child: const Icon(Icons.play_circle_outline))
                    : const Icon(Icons.play_circle_outline),
                selectedIcon: active
                    ? Badge(label: Text('${session.exercises.length}'), child: const Icon(Icons.play_circle))
                    : const Icon(Icons.play_circle),
                label: 'Workout',
              ),
              const NavigationDestination(
                icon: Icon(Icons.list_alt_outlined),
                selectedIcon: Icon(Icons.list_alt),
                label: 'Routines',
              ),
            ],
          );
        },
      ),
    );
  }
}

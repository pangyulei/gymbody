import 'package:flutter/widgets.dart';

/// Tab indexes of the bottom navigation, shared by the shell and the pages
/// that need to navigate to another tab (e.g. "start workout from routine").
abstract final class HomeTabs {
  static const int exercises = 0;
  static const int workout = 1;
  static const int routines = 2;
}

/// Lets a descendant page ask the shell to switch tabs.
class HomeTabScope extends InheritedWidget {
  const HomeTabScope({super.key, required this.selectTab, required super.child});

  final void Function(int index) selectTab;

  static HomeTabScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<HomeTabScope>();

  @override
  bool updateShouldNotify(HomeTabScope oldWidget) => false;
}

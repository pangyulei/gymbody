import 'package:equatable/equatable.dart';

import '../../../domain/models/routine.dart';

enum RoutinesStatus { initial, loading, ready }

class RoutinesState extends Equatable {
  const RoutinesState({this.status = RoutinesStatus.initial, this.routines = const [], this.error});

  final RoutinesStatus status;
  final List<Routine> routines;
  final String? error;

  bool get isEmpty => routines.isEmpty;

  RoutinesState copyWith({RoutinesStatus? status, List<Routine>? routines, String? error, bool clearError = false}) {
    return RoutinesState(
      status: status ?? this.status,
      routines: routines ?? this.routines,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, routines, error];
}

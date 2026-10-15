import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/exercise_repository.dart';
import '../../../domain/models/exercise.dart';

enum CustomExerciseFormStatus { editing, saving, failure }

class CustomExerciseFormState extends Equatable {
  const CustomExerciseFormState({
    this.name = '',
    this.bodyPart = '',
    this.equipment = '',
    this.target = '',
    this.muscleGroup = '',
    this.instructions = '',
    this.posterPath,
    this.gifPath,
    this.status = CustomExerciseFormStatus.editing,
    this.error,
  });

  final String name;
  final String bodyPart;
  final String equipment;
  final String target;
  final String muscleGroup;

  /// One instruction step per line.
  final String instructions;

  /// Absolute paths of the picked files. They are copied into the app
  /// documents directory when the exercise is saved.
  final String? posterPath;
  final String? gifPath;

  final CustomExerciseFormStatus status;
  final String? error;

  bool get isSaving => status == CustomExerciseFormStatus.saving;

  /// Name, body part and equipment are required; media is optional.
  bool get isValid => name.trim().isNotEmpty && bodyPart.trim().isNotEmpty && equipment.trim().isNotEmpty;

  bool get canSubmit => isValid && !isSaving;

  List<String> get instructionSteps =>
      instructions.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList(growable: false);

  CustomExerciseFormState copyWith({
    String? name,
    String? bodyPart,
    String? equipment,
    String? target,
    String? muscleGroup,
    String? instructions,
    String? posterPath,
    String? gifPath,
    bool clearPoster = false,
    bool clearGif = false,
    CustomExerciseFormStatus? status,
    String? error,
    bool clearError = false,
  }) {
    return CustomExerciseFormState(
      name: name ?? this.name,
      bodyPart: bodyPart ?? this.bodyPart,
      equipment: equipment ?? this.equipment,
      target: target ?? this.target,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      instructions: instructions ?? this.instructions,
      posterPath: clearPoster ? null : (posterPath ?? this.posterPath),
      gifPath: clearGif ? null : (gifPath ?? this.gifPath),
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    name,
    bodyPart,
    equipment,
    target,
    muscleGroup,
    instructions,
    posterPath,
    gifPath,
    status,
    error,
  ];
}

/// Drives the "new custom exercise" form.
class CustomExerciseFormCubit extends Cubit<CustomExerciseFormState> {
  CustomExerciseFormCubit({required this._repository}) : super(const CustomExerciseFormState());

  final ExerciseRepository _repository;

  void setName(String value) => emit(state.copyWith(name: value));

  void setBodyPart(String value) => emit(state.copyWith(bodyPart: value));

  void setEquipment(String value) => emit(state.copyWith(equipment: value));

  void setTarget(String value) => emit(state.copyWith(target: value));

  void setMuscleGroup(String value) => emit(state.copyWith(muscleGroup: value));

  void setInstructions(String value) => emit(state.copyWith(instructions: value));

  void setPoster(String? path) =>
      emit(path == null ? state.copyWith(clearPoster: true) : state.copyWith(posterPath: path));

  void setGif(String? path) => emit(path == null ? state.copyWith(clearGif: true) : state.copyWith(gifPath: path));

  /// Persists the exercise, returning it on success.
  Future<Exercise?> submit() async {
    if (!state.canSubmit) return null;
    emit(state.copyWith(status: CustomExerciseFormStatus.saving, clearError: true));

    try {
      final exercise = await _repository.createCustomExercise(
        name: state.name,
        bodyPart: state.bodyPart.trim(),
        equipment: state.equipment.trim(),
        target: state.target.trim(),
        muscleGroup: state.muscleGroup.trim(),
        instructions: state.instructionSteps.join(' '),
        instructionSteps: state.instructionSteps,
        posterSourcePath: state.posterPath,
        gifSourcePath: state.gifPath,
      );
      emit(state.copyWith(status: CustomExerciseFormStatus.editing));
      return exercise;
    } catch (error) {
      emit(state.copyWith(status: CustomExerciseFormStatus.failure, error: 'Could not save the exercise: $error'));
      return null;
    }
  }
}

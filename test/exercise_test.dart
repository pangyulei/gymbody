import 'package:flutter_test/flutter_test.dart';
import 'package:gymbody/data/sources/exercise_asset_source.dart';
import 'package:gymbody/domain/exercise_filter.dart';
import 'package:gymbody/domain/models/exercise.dart';

void main() {
  group('parseExerciseDataset', () {
    test('maps dataset entries into exercises', () {
      const raw = '''
      [
        {
          "id": "0001",
          "name": "3/4 sit-up",
          "body_part": "waist",
          "equipment": "body weight",
          "target": "abs",
          "muscle_group": "hip flexors",
          "secondary_muscles": ["hip flexors", "lower back"],
          "image": "images/0001-2gPfomN.jpg",
          "gif_url": "videos/0001-2gPfomN.gif",
          "instructions": {"en": "Lie flat on your back."},
          "instruction_steps": {"en": ["Lie flat.", "Curl forward."]}
        }
      ]
      ''';

      final exercises = parseExerciseDataset(raw);

      expect(exercises, hasLength(1));
      final exercise = exercises.single;
      expect(exercise.id, '0001');
      expect(exercise.name, '3/4 sit-up');
      expect(exercise.bodyPart, 'waist');
      expect(exercise.equipment, 'body weight');
      expect(exercise.secondaryMuscles, ['hip flexors', 'lower back']);
      expect(exercise.instructionSteps, ['Lie flat.', 'Curl forward.']);
      expect(exercise.posterPath, 'assets/exercises/images/0001-2gPfomN.jpg');
      expect(exercise.gifPath, 'assets/exercises/videos/0001-2gPfomN.gif');
      expect(exercise.isCustom, isFalse);
    });

    test('falls back to another language and to the steps', () {
      const raw = '''
      [
        {
          "id": "0002",
          "name": "Push up",
          "body_part": "chest",
          "equipment": "body weight",
          "instructions": {"fr": "Fais une pompe."},
          "instruction_steps": {"fr": ["Descends.", "Remonte."]}
        }
      ]
      ''';

      final exercise = parseExerciseDataset(raw).single;

      expect(exercise.instructions, 'Fais une pompe.');
      expect(exercise.instructionSteps, ['Descends.', 'Remonte.']);
      expect(exercise.posterPath, isNull);
      expect(exercise.gifPath, isNull);
    });

    test('skips entries without an id or a name', () {
      const raw = '[{"id": "", "name": "Nameless"}, {"name": "No id"}]';

      expect(parseExerciseDataset(raw), isEmpty);
    });

    test('rejects a payload that is not a JSON array', () {
      expect(() => parseExerciseDataset('{"id": "0001"}'), throwsA(isA<FormatException>()));
    });
  });

  group('ExerciseFilter', () {
    const exercises = [
      Exercise(id: 'a', name: 'Bench press', bodyPart: 'chest', equipment: 'barbell', target: 'pectorals'),
      Exercise(id: 'b', name: 'Cable fly', bodyPart: 'chest', equipment: 'cable', target: 'pectorals'),
      Exercise(id: 'c', name: 'Squat', bodyPart: 'upper legs', equipment: 'barbell', target: 'quads'),
      Exercise(id: 'd', name: 'Bicep curl', bodyPart: 'upper arms', equipment: 'dumbbell', target: 'biceps'),
    ];

    List<String> idsOf(List<Exercise> result) => result.map((e) => e.id).toList(growable: false);

    test('orders alphabetically when nothing is favorited', () {
      const filter = ExerciseFilter();

      expect(idsOf(filter.apply(exercises, const {})), ['a', 'd', 'b', 'c']);
    });

    test('always pins favorites to the top', () {
      const filter = ExerciseFilter();

      final result = filter.apply(exercises, const {'c', 'd'});

      // Favorites first (alphabetical: Bicep curl, Squat), then the rest.
      expect(idsOf(result), ['d', 'c', 'a', 'b']);
    });

    test('keeps favorites pinned on top of a filtered result', () {
      const filter = ExerciseFilter(bodyParts: {'chest'});

      expect(idsOf(filter.apply(exercises, const {'b'})), ['b', 'a']);
      expect(idsOf(filter.apply(exercises, const {})), ['a', 'b']);
    });

    test('filters by body part', () {
      const filter = ExerciseFilter(bodyParts: {'chest'});

      expect(idsOf(filter.apply(exercises, const {})), ['a', 'b']);
    });

    test('filters by equipment', () {
      const filter = ExerciseFilter(equipment: {'barbell'});

      expect(idsOf(filter.apply(exercises, const {})), ['a', 'c']);
    });

    test('combines body part and equipment with AND', () {
      const filter = ExerciseFilter(bodyParts: {'chest'}, equipment: {'barbell'});

      expect(idsOf(filter.apply(exercises, const {})), ['a']);
    });

    test('matches the query against name, target and equipment', () {
      expect(idsOf(const ExerciseFilter(query: 'squat').apply(exercises, const {})), ['c']);
      expect(idsOf(const ExerciseFilter(query: 'biceps').apply(exercises, const {})), ['d']);
      expect(idsOf(const ExerciseFilter(query: 'barbell').apply(exercises, const {})), ['a', 'c']);
    });

    test('query is case insensitive and trimmed', () {
      expect(idsOf(const ExerciseFilter(query: '  CABLE  ').apply(exercises, const {})), ['b']);
    });

    test('toggle adds and removes a selection', () {
      var filter = const ExerciseFilter();
      filter = filter.toggleBodyPart('chest');
      expect(filter.bodyParts, {'chest'});

      filter = filter.toggleBodyPart('chest');
      expect(filter.bodyParts, isEmpty);
    });

    test('clearedSelection keeps the query but drops the chips', () {
      const filter = ExerciseFilter(query: 'press', bodyParts: {'chest'}, equipment: {'barbell'});

      final cleared = filter.clearedSelection();

      expect(cleared.query, 'press');
      expect(cleared.bodyParts, isEmpty);
      expect(cleared.equipment, isEmpty);
    });
  });
}

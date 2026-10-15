# GymBody

An offline Flutter (Android) exercise companion built with **Bloc** for state
management and **ObjectBox** for local persistence.

## Features

| # | Feature | Where |
|---|---------|-------|
| 1 | Mark any exercise as a favorite (heart) | Exercises list, exercise detail, workout gallery |
| 2 | Fast filtering by **body part** and **equipment**, free-text search, favorites pinned to the top | Exercises tab |
| 3 | Create custom exercises, pick a **PNG** poster and a **GIF** instruction animation | Exercises tab → `Custom` FAB |
| 4 | Start an empty workout, add exercises, browse them as a **gallery** with prev/next buttons, then save the finished workout as a routine | Workout tab |
| 5 | Exercises are read from bundled assets and never modified; custom exercise media is copied into the app documents directory | `assets/exercises/`, app documents dir |

The app has three bottom-navigation tabs: **Exercises**, **Workout** and
**Routines** (the Workout tab shows a badge with the current exercise count).

## Tech stack

- `flutter_bloc` – events/states for the exercise catalogue, the active workout
  and saved routines.
- `objectbox` + `objectbox_flutter_libs` – favorites, custom exercises and
  routines. The database lives in the application documents directory.
- `file_picker` – picking the PNG poster and GIF instruction.
- `path_provider` – application documents directory.

## Data model

```
assets/exercises/exercises.json   read-only dataset (1324 exercises)
assets/exercises/images/*.jpg     dataset posters
assets/exercises/videos/*.gif     dataset instruction animations
```

The dataset is bundled as assets and only ever read. Anything the user creates
is stored separately:

- `FavoriteEntity` – the exercise ids the user favorited.
- `CustomExerciseEntity` – custom exercise metadata plus absolute paths to its
  poster/gif, which are copied into
  `<app documents>/custom_exercises/`.
- `RoutineEntity` – a name and an ordered list of exercise ids.

Because routine entries are just ids, they resolve against the in-memory
catalogue, so the dataset and custom exercises stay the single source of truth.

## Project layout

```
lib/
  core/            theme, constants, shared widgets (ExerciseImage)
  domain/          Exercise, Routine, ExerciseFilter (pure, unit tested)
  data/
    db/            ObjectBox entities + store bootstrap
    sources/       dataset asset loading/parsing (off the UI isolate)
    repositories/  exercise, favorite and routine repositories
  features/
    shell/         bottom navigation + tab scope
    exercises/     bloc + browse/filter/detail/custom-form screens
    workout/       bloc + gallery, picker and workout screens
    routines/      bloc + list and detail screens

tool/
  sync_zed_devices.dart   regenerates .zed/debug.json from `flutter devices`
.zed/
  debug.json      generated per-device debug configurations
  tasks.json      flutter/objectbox tasks
  settings.json   Dart format-on-save + 120 column width
```

The `ExerciseFilter` model contains the search/filter/sort logic and is free of
Flutter and Bloc dependencies, so it can be unit tested directly.

## Running

```sh
flutter pub get
dart run build_runner build          # regenerates lib/objectbox.g.dart
flutter run
```

> ObjectBox needs generated code. `lib/objectbox.g.dart` and
> `lib/objectbox-model.json` are produced by
> `dart run build_runner build`; re-run it whenever the entities change.

### Android build requirements

- Android SDK (compileSdk 36, minSdk 24 – both the Flutter defaults).
- A JDK 17+ with `JAVA_HOME` set and `java` on `PATH`. Without it
  `flutter build apk` fails with *"No Java Development Kit (JDK) found"*.

## Running from Zed

The project ships a `.zed/` folder with debug configurations, tasks and editor
settings.

### Debugging

1. Install the **Dart** extension in Zed — it registers the `Dart` debug
   adapter, which wraps `flutter debug_adapter`.
2. Generate a configuration per connected device (see below).
3. Press `F4` (`debugger: start`) and pick your device from the list.

`.zed/debug.json` is **generated**, one configuration per connected device:

| Configuration | What it does |
|---|---|
| `Flutter: debug on <device>` | Launches `lib/main.dart` on that device with breakpoints, stepping and inline values |
| `Flutter: run profile on <device>` | Profile mode, no debugger attached, for real-device performance |
| `Flutter: attach to a running app` | Attaches to a VM Service URI printed by the `flutter: run` task |

**Selecting a device:** regenerate the file whenever devices come or go —

```sh
dart tool/sync_zed_devices.dart
```

or run the task `zed: sync debug.json with devices`, then pick the entry for
your device from `F4`. This exists because Zed debug configurations are
static: Zed has no prompt/input mechanism for them, and the Flutter adapter
cannot prompt either, since it launches `flutter run --machine` and `--machine`
disables Flutter's own interactive device picker. This is why each device needs
its own entry instead of a single prompt-based one.

Anything personal goes in the *global* debug tasks file
(`zed: open debug tasks`) — Zed merges it into every workspace and the sync
script never touches it.

Under the hood the adapter runs
`flutter run --machine --start-paused --target lib/main.dart <toolArgs> <args>`,
so `toolArgs` are passed to the Flutter tool (`-d`, `--profile`, `--flavor`,
`--dart-define`) and `args` are passed to the app.

Debugging on Android still needs a JDK (Gradle), see the build requirements
above. Note that **ObjectBox is native-only, so browsers are excluded from the
generated configurations** — use Android or the Windows desktop target.

If you don't need breakpoints, the `flutter: run` task is interactive and *does*
show Flutter's own device picker when several devices are connected.

### Tasks

`task: spawn` lists the project tasks:

- `flutter: run` — runs in a terminal tab, so `r` hot reloads, `R` hot restarts
  and `q` quits, and Flutter prompts for a device when several are connected.
  Re-running cancels the previous run.
- `zed: sync debug.json with devices` — regenerates the debug configurations
- `flutter: run on Android emulator`, `flutter: run on Windows desktop`
- `flutter: test`, `flutter: test current file`
- `flutter: analyze`, `flutter: devices`, `flutter: pub get`
- `objectbox: build_runner build` / `objectbox: build_runner watch`
- `flutter: build apk (debug)`

### Settings

`.zed/settings.json` enables format-on-save with import organisation for Dart
and sets the formatter to 120 columns, matching `formatter.page_width` in
`analysis_options.yaml`.

> `lib/objectbox.g.dart` is generated and does not follow that style, so saving
> it reformats it while regenerating restores the original layout. Run
> `dart format` after regenerating if you want it tidy.

## Tests

```sh
flutter test
```

- `test/exercise_test.dart` – dataset parsing and all filter/sort behaviour.
- `test/dataset_integrity_test.dart` – parses the real bundled dataset and
  checks that every referenced poster/gif exists on disk.

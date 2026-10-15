// Generates .zed/debug.json with one debug configuration per connected device.
//
// Why generate instead of hand-writing: Zed debug configurations are static.
// Zed has no prompt/input mechanism for them, and the Flutter debug adapter
// cannot prompt either — it launches `flutter run --machine`, and `--machine`
// disables Flutter's own interactive device picker. So a device id has to be
// baked into each configuration, which is what this script keeps up to date.
//
// Usage: dart tool/sync_zed_devices.dart
//
// Anything personal or project-independent belongs in the *global* debug tasks
// file (`zed: open debug tasks`), which Zed merges into every workspace and
// this script never touches.
import 'dart:convert';
import 'dart:io';

const String _outputPath = '.zed/debug.json';
const String _programPath = 'lib/main.dart';
const String _worktreeVariable = r'$ZED_WORKTREE_ROOT';
const String _attachPlaceholder = 'http://127.0.0.1:8181/REPLACE_WITH_YOUR_TOKEN=/';

Future<void> main() async {
  final devices = await _readDevices();
  if (devices == null) exit(1);

  final configs = _buildConfigs(devices);

  final output = StringBuffer()
    ..writeln('// GENERATED FILE — do not edit by hand.')
    ..writeln('//')
    ..writeln('// Regenerate after plugging in or unplugging a device:')
    ..writeln('//   dart tool/sync_zed_devices.dart')
    ..writeln('// or run the Zed task "zed: sync debug.json with devices".')
    ..writeln('//')
    ..writeln('// Web browsers are skipped on purpose: ObjectBox is native-only, so the')
    ..writeln('// app cannot run on the web target.')
    ..writeln()
    ..writeln(const JsonEncoder.withIndent('  ').convert(configs));

  final file = File(_outputPath);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(output.toString());

  stdout.writeln('Wrote ${file.path} with ${configs.length} configurations:');
  for (final config in configs) {
    stdout.writeln('  - ${config['label']}');
  }
}

/// Runs `flutter devices --machine`, returning `null` (after printing the
/// reason) when the tool fails.
Future<List<_Device>?> _readDevices() async {
  final ProcessResult result;
  try {
    result = await Process.run('flutter', const ['devices', '--machine'], runInShell: true);
  } on ProcessException catch (error) {
    stderr.writeln('Could not run the flutter tool: $error');
    return null;
  }

  if (result.exitCode != 0) {
    stderr.writeln('flutter devices failed (exit ${result.exitCode}).');
    stderr.writeln('${result.stderr}'.trim());
    return null;
  }

  final text = '${result.stdout}';
  // The tool occasionally prints progress before the JSON payload.
  final start = text.indexOf('[');
  if (start < 0) {
    stderr.writeln('Unexpected output from flutter devices:');
    stderr.writeln(text.trim());
    return null;
  }

  final decoded = jsonDecode(text.substring(start));
  if (decoded is! List) {
    stderr.writeln('Unexpected output from flutter devices: not a JSON array.');
    return null;
  }

  return <_Device>[
    for (final entry in decoded)
      if (entry is Map)
        _Device(
          name: '${entry['name'] ?? 'Unknown'}',
          id: '${entry['id'] ?? ''}',
          targetPlatform: '${entry['targetPlatform'] ?? ''}',
          emulator: entry['emulator'] == true,
          supported: entry['isSupported'] == true,
        ),
  ];
}

List<Map<String, Object?>> _buildConfigs(List<_Device> devices) {
  final usable = devices
      .where((device) => device.supported && !device.isWeb && device.id.isNotEmpty)
      .toList(growable: false);

  final configs = <Map<String, Object?>>[];
  final labels = <String>{};

  for (final device in usable) {
    var label = 'Flutter: debug on ${device.name}${device.labelSuffix}';
    if (!labels.add(label)) {
      // Two devices sharing a name: disambiguate with the id.
      label = 'Flutter: debug on ${device.name} [${device.id}]';
      labels.add(label);
    }
    configs.add(_launchConfig(label: label, deviceId: device.id));
  }

  _Device? android;
  for (final device in usable) {
    if (device.targetPlatform.startsWith('android')) {
      android = device;
      break;
    }
  }
  if (android != null) {
    configs.add(
      _launchConfig(
        label: 'Flutter: run profile on ${android.name}',
        deviceId: android.id,
        // `--profile` in toolArgs is what selects profile mode, and the
        // debugger is not attached in this mode.
        toolArgs: const ['--profile'],
        flutterMode: 'profile',
      ),
    );
  }

  configs.add(<String, Object?>{
    'label': 'Flutter: attach to a running app',
    'adapter': 'Dart',
    'type': 'flutter',
    'request': 'attach',
    'program': _programPath,
    'cwd': _worktreeVariable,
    // Paste the "Dart VM Service" URI printed by the `flutter: run` task.
    'vmServiceUri': _attachPlaceholder,
  });

  return configs;
}

Map<String, Object?> _launchConfig({
  required String label,
  required String deviceId,
  List<String>? toolArgs,
  String flutterMode = 'debug',
}) {
  return <String, Object?>{
    'label': label,
    'adapter': 'Dart',
    'type': 'flutter',
    'request': 'launch',
    'program': _programPath,
    'cwd': _worktreeVariable,
    // The Dart extension forwards this to the flutter tool as `-d <deviceId>`.
    'deviceId': deviceId,
    'toolArgs': ?toolArgs,
    'flutterMode': flutterMode,
    'stopOnEntry': false,
  };
}

class _Device {
  const _Device({
    required this.name,
    required this.id,
    required this.targetPlatform,
    required this.emulator,
    required this.supported,
  });

  final String name;
  final String id;
  final String targetPlatform;
  final bool emulator;
  final bool supported;

  bool get isWeb => targetPlatform.startsWith('web');

  /// Human readable hint appended to the label when the device name alone is
  /// ambiguous. Desktops are already named after their platform.
  String get labelSuffix {
    if (targetPlatform.startsWith('android')) {
      return emulator ? ' (Android emulator)' : ' (Android)';
    }
    if (targetPlatform.startsWith('ios')) return ' (iOS)';
    if (isWeb) return ' (web)';
    return '';
  }
}

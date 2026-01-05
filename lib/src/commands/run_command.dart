import 'dart:io';

import 'package:path/path.dart' as path;

import '../utils/utils.dart';
import 'commands.dart';

/// Command to run the Flutter application.
class RunCommand implements BaseCommand {
  @override
  String get name => 'run';

  @override
  String get description => 'Run the Flutter app from root/lib/main.dart.';

  @override
  void execute(List<String> arguments) async {
    try {
      final rootPath = Directory.current.path;

      // Check if root/lib/main.dart exists
      final mainDartPath = path.join(rootPath, 'lib', 'main.dart');
      if (!File(mainDartPath).existsSync()) {
        Logger.error('lib/main.dart not found.');
        Logger.info('Run "flutist init" first to create the project.');
        exit(1);
      }

      Logger.info('Running Flutter app from root...');

      // Run flutter from root directory (main.dart is in lib/main.dart)
      final process = await Process.start(
        'flutter',
        ['run', ...arguments],
        workingDirectory: rootPath,
        mode: ProcessStartMode.inheritStdio,
      );

      final exitCode = await process.exitCode;
      exit(exitCode);
    } catch (e) {
      Logger.error('Failed to run app: $e');
      exit(1);
    }
  }
}

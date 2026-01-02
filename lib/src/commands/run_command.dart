import 'dart:io';

import 'package:path/path.dart' as path;

import '../utils/utils.dart';
import 'commands.dart';

/// Command to run the Flutter application.
class RunCommand implements BaseCommand {
  @override
  String get name => 'run';

  @override
  String get description => 'Run the Flutter app from root/app/main.dart.';

  @override
  void execute(List<String> arguments) async {
    try {
      final rootPath = Directory.current.path;
      final appPath = path.join(rootPath, 'app');

      // Check if app directory exists
      if (!Directory(appPath).existsSync()) {
        Logger.error('app directory not found.');
        Logger.info('Run "flutist init" first to create the app module.');
        exit(1);
      }

      // Check if app/lib/main.dart exists
      final mainDartPath = path.join(appPath, 'lib', 'main.dart');
      if (!File(mainDartPath).existsSync()) {
        Logger.error('app/lib/main.dart not found.');
        exit(1);
      }

      Logger.info('Running Flutter app from root...');

      // Run flutter run at root level with app/lib/main.dart as target
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

import 'dart:io';

import 'package:args/args.dart';
import 'package:flutist/flutist.dart';

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    // TODO: Print help message
  }

  try {
    final ArgParser parser = ArgParser();
    final argResults = parser.parse(arguments);
    final commandName = argResults.arguments[0];

    switch (commandName) {
      /// tuist init
      case 'init':
        InitCommand().execute(argResults);
        break;

      /// tuist generate
      case 'generate':
        GenerateCommand().execute(argResults);
        break;

      /// tuist create --name <module_name> --path <path> --options <ModuleType>
      case 'create':
        CreateCommand().execute(argResults);
        break;
      default:
        break;
    }
  } catch (e) {
    Logger.error(e.toString());
    exit(1);
  }
}

import 'dart:io';

import 'package:flutist/flutist.dart';

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    // TODO: Print help message
  }

  try {
    // Get command name (first argument)
    final commandName = arguments[0];

    // Get remaining arguments for the command
    final commandArgs = arguments.skip(1).toList();

    switch (commandName) {
      /// flutist init
      case 'init':
        InitCommand().execute(commandArgs);
        break;

      /// flutist generate
      case 'generate':
        GenerateCommand().execute(commandArgs);
        break;

      /// flutist create --name <module_name> --path <path> --options <ModuleType>
      case 'create':
        CreateCommand().execute(commandArgs);
        break;

      /// flutist run
      case 'run':
        RunCommand().execute(commandArgs);
        break;

      /// flutist pub add <package_name>
      case 'pub':
        PubCommand().execute(commandArgs);
        break;

      /// flutist scaffold <template_name> --name <name> --path <path>
      case 'scaffold':
        ScaffoldCommand().execute(commandArgs);
        break;

      /// flutist graph
      case 'graph':
        GraphCommand().execute(commandArgs);
        break;

      /// flutist help
      default:
        Logger.error('Unknown command: $commandName');
        exit(1);
    }
  } catch (e) {
    Logger.error(e.toString());
    exit(1);
  }
}

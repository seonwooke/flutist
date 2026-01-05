import 'dart:io';

import 'package:flutist/flutist.dart';

/// Main entry point for Flutist CLI.
/// Parses command-line arguments and executes the appropriate command.
void main(List<String> arguments) async {
  try {
    if (arguments.isEmpty) {
      HelpCommand().execute([]);
      return;
    }

    final commandName = arguments[0];
    final commandArgs = arguments.skip(1).toList();

    switch (commandName) {
      case 'init':
        InitCommand().execute(commandArgs);
        break;

      case 'generate':
        GenerateCommand().execute(commandArgs);
        break;

      case 'create':
        CreateCommand().execute(commandArgs);
        break;

      case 'pub':
        PubCommand().execute(commandArgs);
        break;

      case 'scaffold':
        ScaffoldCommand().execute(commandArgs);
        break;

      case 'graph':
        GraphCommand().execute(commandArgs);
        break;

      case 'help':
        HelpCommand().execute(commandArgs);
        break;

      default:
        Logger.error('Unknown command: $commandName');
        Logger.info('Run "flutist help" to see all available commands.');
        exit(1);
    }
  } catch (e) {
    Logger.error(e.toString());
    exit(1);
  }
}

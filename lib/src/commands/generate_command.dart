import 'package:args/args.dart';

import 'commands.dart';

class GenerateCommand implements BaseCommand {
  @override
  String get name => 'generate';

  @override
  String get description =>
      'Sync all pubspec.yaml files based on project.dart.';

  @override
  void execute(ArgResults arguments) {
    // TODO: Implement the command logic here
  }
}

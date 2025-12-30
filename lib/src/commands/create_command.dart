import 'package:args/args.dart';

import 'commands.dart';

class CreateCommand implements BaseCommand {
  @override
  String get name => 'create';

  @override
  String get description => 'Create a new module in the Flutist project.';

  @override
  void execute(ArgResults arguments) {
    // TODO: Implement the command logic here
  }
}

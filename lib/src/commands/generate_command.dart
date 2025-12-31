import 'commands.dart';

class GenerateCommand implements BaseCommand {
  @override
  String get name => 'generate';

  @override
  String get description =>
      'Sync all pubspec.yaml files based on project.dart.';

  @override
  void execute(List<String> arguments) {
    // TODO: Implement the command logic here
  }
}

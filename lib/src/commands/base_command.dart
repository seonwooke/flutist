/// Base interface for all Flutist CLI commands.
abstract class BaseCommand {
  /// Command name (e.g., 'init').
  String get name;

  /// Brief description of what the command does.
  String get description;

  /// Executes the command with the given arguments.
  void execute(List<String> arguments);
}

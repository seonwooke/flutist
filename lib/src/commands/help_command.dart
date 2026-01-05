import 'dart:io';

import '../utils/utils.dart';
import 'commands.dart';

/// Command to display help information.
class HelpCommand implements BaseCommand {
  @override
  String get name => 'help';

  @override
  String get description => 'Display help information for Flutist commands';

  @override
  void execute(List<String> arguments) {
    if (arguments.isEmpty) {
      _showGeneralHelp();
    } else {
      _showCommandHelp(arguments[0]);
    }
  }

  /// Shows general help with all available commands.
  void _showGeneralHelp() {
    Logger.banner();
    print('''
USAGE:
  flutist <command> [arguments]

AVAILABLE COMMANDS:
  init        Initialize a new Flutist project with Workspace support
  create      Create a new module in the Flutist project
  generate    Sync all pubspec.yaml files based on project.dart
  pub         Manage dependencies in package.dart
  scaffold    Generate code from templates
  graph       Generate dependency graph of modules
  help        Display help information for Flutist commands

QUICK START:
  1. Initialize a new project:
     flutist init

  2. Create a new module:
     flutist create --path <path> --name <name> --options <type>

  3. Generate pubspec files:
     flutist generate

For more information about a specific command, use:
  flutist help <command>
  flutist <command> --help

EXAMPLES:
  flutist init
  flutist create --path features --name login --options feature
  flutist generate
  flutist pub add http
  flutist scaffold list
  flutist graph --format mermaid
''');
  }

  /// Shows detailed help for a specific command.
  void _showCommandHelp(String commandName) {
    switch (commandName) {
      case 'init':
        _showInitHelp();
        break;
      case 'create':
        _showCreateHelp();
        break;
      case 'generate':
        _showGenerateHelp();
        break;
      case 'pub':
        _showPubHelp();
        break;
      case 'scaffold':
        _showScaffoldHelp();
        break;
      case 'graph':
        _showGraphHelp();
        break;
      case 'help':
        _showGeneralHelp();
        break;
      default:
        Logger.error('Unknown command: $commandName');
        Logger.info('Run "flutist help" to see all available commands.');
        exit(1);
    }
  }

  void _showInitHelp() {
    print('''
COMMAND: init
DESCRIPTION: Initialize a new Flutist project with Workspace support

USAGE:
  flutist init

OVERVIEW:
  This command sets up a new Flutist project in the current directory.
  It creates the necessary configuration files and initializes the workspace
  structure with a default "app" module.

WHAT IT DOES:
  • Creates project.dart and package.dart configuration files
  • Sets up pubspec.yaml with workspace configuration
  • Creates a default "app" module
  • Generates example scaffold templates
  • Creates flutist_gen.dart for code generation

EXAMPLES:
  flutist init
''');
  }

  void _showCreateHelp() {
    print('''
COMMAND: create
DESCRIPTION: Create a new module in the Flutist project

USAGE:
  flutist create --path <path> --name <name> --options <type>

REQUIRED OPTIONS:
  --path, -p <path>     Directory path where the module will be created
  --name, -n <name>     Name of the module
  --options, -o <type>   Module type (feature, library, standard, simple)

MODULE TYPES:
  feature    Feature module with full structure
  library    Library module for shared code
  standard   Standard module structure
  simple     Simple module with minimal structure

EXAMPLES:
  flutist create --path features --name login --options feature
  flutist create --path lib --name utils --options library
  flutist create -p shared -n models -o standard
''');
  }

  void _showGenerateHelp() {
    print('''
COMMAND: generate
DESCRIPTION: Sync all pubspec.yaml files based on project.dart

USAGE:
  flutist generate

OVERVIEW:
  This command synchronizes all pubspec.yaml files in your workspace
  based on the dependencies defined in project.dart. It ensures that
  all modules have the correct dependencies configured.

WHAT IT DOES:
  • Parses project.dart to get module dependencies
  • Updates each module's pubspec.yaml with correct dependencies
  • Regenerates flutist_gen.dart

EXAMPLES:
  flutist generate
''');
  }

  void _showPubHelp() {
    print('''
COMMAND: pub
DESCRIPTION: Manage dependencies in package.dart

USAGE:
  flutist pub add <package_name> [--version <version>]

SUBCOMMANDS:
  add <package>    Add a new dependency to package.dart

OPTIONS:
  --version <version>   Specify package version (optional)

OVERVIEW:
  This command manages dependencies in your package.dart file.
  After adding a dependency, you should run "flutist generate"
  to sync the changes to all module pubspec.yaml files.

EXAMPLES:
  flutist pub add http
  flutist pub add provider --version ^2.0.0
  flutist pub add bloc
''');
  }

  void _showScaffoldHelp() {
    print('''
COMMAND: scaffold
DESCRIPTION: Generate code from templates

USAGE:
  flutist scaffold <template> --name <name> [options]
  flutist scaffold list
  flutist scaffold help [subcommand]

SUBCOMMANDS:
  list                    Lists available scaffold templates
  help <subcommand>       Show help for a specific subcommand

REQUIRED OPTIONS:
  --name <name>           Name for the generated files

OPTIONAL OPTIONS:
  --path <path>           Output path (default: current directory)
  -h, --help              Show help information

OVERVIEW:
  This command generates code from user-defined templates located in
  flutist/templates/. Templates use variables like {{name}}, {{Name}},
  and {{NAME}} for different naming conventions.

TEMPLATE VARIABLES:
  {{name}}                snake_case version (e.g., user_profile)
  {{Name}}                PascalCase version (e.g., UserProfile)
  {{NAME}}                UPPER_CASE version (e.g., USER_PROFILE)

EXAMPLES:
  flutist scaffold list
  flutist scaffold feature --name login
  flutist scaffold feature --name user_profile --path lib/features
''');
  }

  void _showGraphHelp() {
    print('''
COMMAND: graph
DESCRIPTION: Generate dependency graph of modules

USAGE:
  flutist graph [options]

OPTIONS:
  --format, -f <format>   Output format (mermaid, dot, ascii)
                          Default: mermaid
  --output, -o <file>     Output file path (for mermaid/dot)
  --open                  Open in browser (mermaid only)
  -h, --help              Show help information

FORMATS:
  mermaid    Mermaid diagram format (for documentation)
  dot        Graphviz DOT format
  ascii      ASCII art representation

OVERVIEW:
  This command analyzes your project structure and generates a
  dependency graph showing relationships between modules.

EXAMPLES:
  flutist graph
  flutist graph --format mermaid
  flutist graph --format dot --output graph.dot
  flutist graph --format mermaid --open
  flutist graph --format ascii
''');
  }
}

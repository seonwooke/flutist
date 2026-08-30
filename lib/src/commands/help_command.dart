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
  check       Check architecture rules for module dependencies
  pub         Manage dependencies in package.dart
  scaffold    Generate code from templates
  test        Run tests for all modules in parallel
  graph       Generate dependency graph of modules
  help        Display help information for Flutist commands

QUICK START:
  1. Initialize a new project:
     flutist init

  2. Create a new module:
     flutist create --name <name> --path <path> --options <type>

  3. Generate pubspec files:
     flutist generate

For more information about a specific command, use:
  flutist help <command>
  flutist <command> --help

EXAMPLES:
  flutist init
  flutist create --name login --path features --options clean
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
      case 'check':
        _showCheckHelp();
        break;
      case 'pub':
        _showPubHelp();
        break;
      case 'scaffold':
        _showScaffoldHelp();
        break;
      case 'test':
        _showTestHelp();
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
  flutist create --name <name> --path <path> [--options <type>]

REQUIRED OPTIONS:
  --name, -n <name>     Name of the module
  --path, -p <path>     Directory path where the module will be created

OPTIONAL OPTIONS:
  --options, -o <type>  Scaffold type: clean, micro, lite
                        (omit to create a single package with no layers)

SCAFFOLD TYPES:
  clean      Clean Architecture (Domain, Data, Presentation)
  micro      Microfeature Architecture (Interface, Implementation, Testing, Tests, Example)
  lite       Microfeature lite (Interface, Implementation, Testing, Tests)

EXAMPLES:
  flutist create --name login --path features --options clean
  flutist create --name network --path lib --options micro
  flutist create -n models -p core -o lite
  flutist create --name utils --path core
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

WHAT IT TOUCHES:
  Only the dependencies and dev_dependencies sections, and within them
  only names Flutist owns. A name is Flutist's if package.dart declares
  it, or if it belongs to a module in the workspace.

  Kept as written:
    • path: and git: dependencies you added by hand
    • pub.dev packages not declared in package.dart
    • sdk entries (flutter, flutter_test, flutter_localizations)
    • every other section (flutter:, assets:, resolution:, environment:)
    • modules that project.dart does not list, which are never opened

  Rewritten:
    • versions of packages declared in package.dart
    • names Flutist owns that project.dart does not reference, which are
      removed; generate names each one and the declaration that keeps it

  Wiring one workspace module to another by editing a pubspec.yaml does
  not stick. Declare it in project.dart under the module's modules list.

  Comments inside dependencies and dev_dependencies are not preserved;
  those sections are re-serialized in full.

EXAMPLES:
  flutist generate
''');
  }

  void _showCheckHelp() {
    print('''
COMMAND: check
DESCRIPTION: Check architecture rules for module dependencies

USAGE:
  flutist check

OVERVIEW:
  Validates that module dependencies follow architecture rules.
  Also runs automatically during `flutist generate` when strictMode is enabled.

RULES:
  • Implementation layers must not be referenced directly (use Interface instead)
  • Circular dependencies are not allowed
  • Testing layers should only be referenced by test modules
  • Example layers should not be referenced as dependencies
  • Clean module layers: Domain must not depend on Data/Presentation;
    Data must not depend on Presentation

OPTIONS (in ProjectOptions):
  strictMode: true          Enable/disable enforcement (default: true)
  compositionRoots: ['app'] Modules allowed to reference Implementation directly

EXAMPLES:
  flutist check
''');
  }

  void _showPubHelp() {
    print('''
COMMAND: pub
DESCRIPTION: Manage dependencies in package.dart

USAGE:
  flutist pub add <package_name> [<package_name2> ...] [--version <constraint>]
  flutist pub delete <package_name> [<package_name2> ...] [--dry-run] [-y]

SUBCOMMANDS:
  add <package>...       Add one or more dependencies to package.dart
  delete <package>...    Remove one or more dependencies from package.dart

OPTIONS (add):
  --version <constraint>   Pin a version constraint (e.g. ^2.0.0).
                           Only valid when adding a single package.

OPTIONS (delete):
  --dry-run                Print what would change without writing files.
  -y, --yes                Skip the confirmation prompt.

OVERVIEW:
  This command manages dependencies in your package.dart file.
  After modifying dependencies, you should run "flutist generate"
  to sync the changes to all module pubspec.yaml files.

  `pub delete` prints the full plan first (including any
  `package.dependencies.xxx` references it will remove from project.dart)
  and waits for a y/n confirmation. Pass -y to skip the prompt in scripts.

LOCAL AND GIT PACKAGES:
  `pub add` resolves from pub.dev. Packages on disk or in a Git repository
  are declared in package.dart by hand, then picked up by "flutist generate":

    Dependency.path(name: 'design_system', path: 'shared/design_system'),
    Dependency.git(
      name: 'analytics',
      url: 'https://github.com/acme/analytics.git',
      ref: 'main',
    ),

  A path is written relative to package.dart, not to the module using it.
  Flutist re-anchors it for each module, so the same line resolves from any
  depth in the workspace. `pub delete` removes all three kinds.

EXAMPLES:
  flutist pub add http
  flutist pub add http dio bloc
  flutist pub add provider --version ^2.0.0
  flutist pub delete http
  flutist pub delete http dio
  flutist pub delete provider --dry-run
  flutist pub delete provider -y
''');
  }

  void _showTestHelp() {
    print('''
COMMAND: test
DESCRIPTION: Run tests for all modules in parallel

USAGE:
  flutist test [options]

OPTIONS:
  -m, --module <name>   Run tests for a specific module only
  -h, --help            Show help information

OVERVIEW:
  Finds all modules with a test/ directory and runs dart test
  in parallel. Reports results with pass/fail summary.

EXAMPLES:
  flutist test
  flutist test --module login
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

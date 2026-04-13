import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../utils/utils.dart';
import 'commands.dart';

/// Command to generate code from user-defined templates.
class ScaffoldCommand implements BaseCommand {
  @override
  String get name => 'scaffold';

  @override
  String get description => 'Generate code from templates';

  @override
  void execute(List<String> arguments) {
    if (arguments.isEmpty ||
        arguments.contains('--help') ||
        arguments.contains('-h')) {
      _showHelp();
      return;
    }

    final subCommand = arguments[0];

    switch (subCommand) {
      case 'list':
        _listTemplates();
        break;
      case 'help':
        if (arguments.length > 1) {
          _showSubcommandHelp(arguments[1]);
        } else {
          _showHelp();
        }
        break;
      default:
        _generateFromTemplate(subCommand, arguments.skip(1).toList());
    }
  }

  void _showHelp() {
    print('''
OVERVIEW: Generates new code based on a template

USAGE: flutist scaffold <template> [options] <subcommand>

ARGUMENTS:
  <template>              Name of template you want to use

OPTIONS:
  --name <name>           Name for the generated files (required)
  --path <path>           Output path (overrides template.yaml default)
  --<attribute> <value>   Custom attribute defined in template.yaml
  -h, --help              Show help information

SUBCOMMANDS:
  list                    Lists available scaffold templates
  help <subcommand>       Show help for a specific subcommand

EXAMPLES:
  flutist scaffold list
  flutist scaffold feature --name login
  flutist scaffold feature --name login --path lib/features
  flutist scaffold feature --name login --useBloc true

TEMPLATE VARIABLES:
  {{name}}                snake_case (e.g., user_profile)
  {{name | pascal_case}}  PascalCase (e.g., UserProfile)
  {{name | camel_case}}   camelCase (e.g., userProfile)
  {{name | upper_case}}   UPPER_CASE (e.g., USER_PROFILE)
  {{name | snake_case}}   snake_case (e.g., user_profile)
  {{Name}}                PascalCase — legacy shorthand
  {{NAME}}                UPPER_CASE — legacy shorthand
  {{custom}}              Custom attributes from template.yaml

See 'flutist scaffold help <subcommand>' for detailed help.
''');
  }

  void _showSubcommandHelp(String subCommand) {
    switch (subCommand) {
      case 'list':
        print('''
OVERVIEW: Lists available scaffold templates

USAGE: flutist scaffold list

TEMPLATE.YAML STRUCTURE:
  description: "Feature template with BLoC pattern"
  attributes:
    - name: name
      required: true
    - name: path
      required: false
      default: "lib/features"
    - name: useBloc
      required: false
      default: "true"
  items:
    - type: file
      path: "{{path}}/{{name | snake_case}}_bloc.dart"
      templatePath: "bloc.dart.template"
      if: "useBloc == 'true'"
    - type: string
      path: "{{path}}/README.md"
      contents: |
        # {{name | pascal_case}}
        Auto-generated module.
    - type: directory
      path: "{{path}}/assets"
      sourcePath: "assets"

EXAMPLES:
  flutist scaffold list
''');
        break;
      default:
        Logger.warn('Unknown subcommand: $subCommand');
        _showHelp();
    }
  }

  void _listTemplates() {
    final rootPath = Directory.current.path;
    final templatesDir = Directory(p.join(rootPath, 'flutist', 'templates'));

    if (!templatesDir.existsSync()) {
      Logger.warn('No templates directory found.');
      Logger.info('');
      Logger.info('Create templates in: flutist/templates/');
      Logger.info('');
      Logger.info('Example structure:');
      Logger.info('  flutist/templates/');
      Logger.info('    feature/');
      Logger.info('      template.yaml');
      Logger.info('      {{name}}_bloc.dart.template');
      return;
    }

    final templates = templatesDir
        .listSync()
        .whereType<Directory>()
        .map((dir) => p.basename(dir.path))
        .toList();

    if (templates.isEmpty) {
      Logger.warn('No templates found in flutist/templates/');
      return;
    }

    Logger.info('📋 Available templates:');
    Logger.info('');

    for (final template in templates) {
      final templateDir = Directory(p.join(templatesDir.path, template));
      final configFile = File(p.join(templateDir.path, 'template.yaml'));

      if (configFile.existsSync()) {
        try {
          final config = loadYaml(configFile.readAsStringSync()) as Map;
          final description = config['description'] ?? 'No description';
          final attributes = config['attributes'] as List?;

          Logger.info('  • $template');
          Logger.info('    $description');

          if (attributes != null && attributes.isNotEmpty) {
            final attrNames = attributes.map((attr) {
              if (attr is Map) {
                final name = attr['name'];
                final required = attr['required'] == true;
                return required ? '$name (required)' : name;
              }
              return attr.toString();
            }).join(', ');
            Logger.info('    Attributes: $attrNames');
          }

          final items = config['items'] as List?;
          if (items != null) {
            Logger.info('    Files: ${items.length} items');
          }
        } catch (e) {
          Logger.info('  • $template');
          Logger.info('    (invalid template.yaml)');
        }
      } else {
        Logger.info('  • $template');
        Logger.info('    (no template.yaml - using simple mode)');

        final templateFiles = templateDir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.template'))
            .map((file) => p.basename(file.path))
            .toList();

        if (templateFiles.isNotEmpty) {
          Logger.info('    Files: ${templateFiles.join(", ")}');
        }
      }

      Logger.info('');
    }

    Logger.info('Usage: flutist scaffold <template> --name <name> [options]');
  }

  /// Generates files from a template.
  ///
  /// Loads template.yaml early to discover custom attributes,
  /// then builds ArgParser dynamically so `--attribute` flags work.
  void _generateFromTemplate(String templateName, List<String> arguments) {
    final rootPath = Directory.current.path;
    final templateDir = Directory(
      p.join(rootPath, 'flutist', 'templates', templateName),
    );

    if (!templateDir.existsSync()) {
      Logger.error('Template "$templateName" not found.');
      Logger.info('');
      Logger.info('Available templates: run "flutist scaffold list"');
      exit(1);
    }

    // Load template.yaml early to discover custom attribute definitions.
    final configFile = File(p.join(templateDir.path, 'template.yaml'));
    Map? config;
    List? configAttributes;

    if (configFile.existsSync()) {
      try {
        config = loadYaml(configFile.readAsStringSync()) as Map;
        configAttributes = config['attributes'] as List?;
      } catch (e) {
        Logger.error('Failed to parse template.yaml: $e');
        exit(1);
      }
    }

    // Build ArgParser with both standard and custom attributes.
    final parser = ArgParser()
      ..addOption('name', help: 'Name for the generated files', mandatory: true)
      ..addOption('path', help: 'Output path (overrides template.yaml default)')
      ..addFlag('help',
          abbr: 'h', help: 'Show help information', negatable: false);

    if (configAttributes != null) {
      for (final attr in configAttributes) {
        if (attr is Map) {
          final attrName = attr['name'] as String;
          if (attrName != 'name' && attrName != 'path') {
            parser.addOption(
              attrName,
              help: attr['description'] as String? ?? attrName,
            );
          }
        }
      }
    }

    ArgResults result;
    try {
      result = parser.parse(arguments);
    } catch (e) {
      Logger.error('Failed to parse arguments: $e');
      Logger.info('');
      Logger.info(
          'Usage: flutist scaffold $templateName --name <name> [options]');
      exit(1);
    }

    if (result['help'] as bool) {
      print('''
OVERVIEW: Generate code from the "$templateName" template

USAGE: flutist scaffold $templateName --name <name> [options]

OPTIONS:
  --name <name>           Name for the generated files (required)
  --path <path>           Output path (overrides template.yaml default)
  --<attribute> <value>   Custom attribute defined in template.yaml
  -h, --help              Show help information

TEMPLATE VARIABLES:
  {{name}}                snake_case (e.g., user_profile)
  {{name | pascal_case}}  PascalCase (e.g., UserProfile)
  {{name | camel_case}}   camelCase (e.g., userProfile)
  {{name | upper_case}}   UPPER_CASE (e.g., USER_PROFILE)
''');
      return;
    }

    final name = result['name'] as String;
    final attributes = <String, String>{'name': name};

    if (result['path'] != null) {
      attributes['path'] = result['path'] as String;
    }

    // Collect custom attributes from parsed args.
    for (final key in result.options) {
      if (key != 'name' && key != 'path' && key != 'help') {
        final value = result[key];
        if (value != null) {
          attributes[key] = value.toString();
        }
      }
    }

    // Fill missing attributes: required → error, optional → use default silently.
    if (configAttributes != null) {
      for (final attr in configAttributes) {
        if (attr is! Map) continue;
        final attrName = attr['name'] as String;
        final required = attr['required'] == true;
        final defaultValue = attr['default'] as String?;

        if (!attributes.containsKey(attrName)) {
          if (required) {
            Logger.error('Required attribute "--$attrName" is missing.');
            Logger.info('');
            Logger.info(
                'Usage: flutist scaffold $templateName --name <name> [options]');
            exit(1);
          } else if (defaultValue != null) {
            attributes[attrName] = defaultValue;
          }
        }
      }
    }

    Logger.info('🏗️  Generating from template: $templateName');
    Logger.info('   Name: $name');
    for (final entry in attributes.entries) {
      if (entry.key != 'name') {
        Logger.info('   ${entry.key}: ${entry.value}');
      }
    }
    Logger.info('');

    if (config != null) {
      _processAdvancedTemplate(templateDir, config, attributes);
    } else {
      _processSimpleTemplate(templateDir, attributes);
    }

    Logger.success('Scaffold completed!');
  }

  /// Processes template using template.yaml configuration.
  void _processAdvancedTemplate(
    Directory templateDir,
    Map config,
    Map<String, String> attributes,
  ) {
    final items = config['items'] as List?;
    if (items == null || items.isEmpty) {
      Logger.warn('No items defined in template.yaml');
      return;
    }

    for (final item in items) {
      if (item is! Map) continue;

      // ③ Conditional generation: skip item if if: condition is false.
      final condition = item['if'] as String?;
      if (!_evaluateCondition(condition, attributes)) continue;

      final type = item['type'] as String?;

      switch (type) {
        case 'file':
          _processFileItem(templateDir, item, attributes);
          break;
        case 'string':
          _processStringItem(item, attributes);
          break;
        case 'directory':
          _processDirectoryItem(templateDir, item, attributes);
          break;
        default:
          Logger.warn('Unknown item type: $type');
      }
    }
  }

  /// Processes a file item from template.yaml.
  void _processFileItem(
    Directory templateDir,
    Map item,
    Map<String, String> attributes,
  ) {
    final outputPath = item['path'] as String?;
    final templatePath = item['templatePath'] as String?;

    if (outputPath == null || templatePath == null) {
      Logger.warn('Invalid file item: missing path or templatePath');
      return;
    }

    final resolvedOutputPath = _replaceVariables(outputPath, attributes);

    final templateFile = File(p.join(templateDir.path, templatePath));
    if (!templateFile.existsSync()) {
      Logger.warn('Template file not found: $templatePath');
      return;
    }

    var content = templateFile.readAsStringSync();
    content = _replaceVariables(content, attributes);

    final rootPath = Directory.current.path;
    final outputFile = File(p.join(rootPath, resolvedOutputPath));
    outputFile.createSync(recursive: true);
    outputFile.writeAsStringSync(content);

    Logger.info('  ✓ Created: $resolvedOutputPath');
  }

  /// Processes a string item from template.yaml (⑤ inline content).
  void _processStringItem(Map item, Map<String, String> attributes) {
    final outputPath = item['path'] as String?;
    final contents = item['contents'] as String?;

    if (outputPath == null || contents == null) {
      Logger.warn('Invalid string item: missing path or contents');
      return;
    }

    final resolvedOutputPath = _replaceVariables(outputPath, attributes);
    final resolvedContents = _replaceVariables(contents, attributes);

    final rootPath = Directory.current.path;
    final outputFile = File(p.join(rootPath, resolvedOutputPath));
    outputFile.createSync(recursive: true);
    outputFile.writeAsStringSync(resolvedContents);

    Logger.info('  ✓ Created: $resolvedOutputPath');
  }

  /// Processes a directory item from template.yaml.
  void _processDirectoryItem(
    Directory templateDir,
    Map item,
    Map<String, String> attributes,
  ) {
    final outputPath = item['path'] as String?;
    final sourcePath = item['sourcePath'] as String?;

    if (outputPath == null || sourcePath == null) {
      Logger.warn('Invalid directory item: missing path or sourcePath');
      return;
    }

    final resolvedOutputPath = _replaceVariables(outputPath, attributes);

    final sourceDir = Directory(p.join(templateDir.path, sourcePath));
    if (!sourceDir.existsSync()) {
      Logger.warn('Source directory not found: $sourcePath');
      return;
    }

    final rootPath = Directory.current.path;
    _copyDirectory(sourceDir, Directory(p.join(rootPath, resolvedOutputPath)));

    Logger.info('  ✓ Copied directory: $resolvedOutputPath');
  }

  /// Processes template in simple mode (no template.yaml).
  void _processSimpleTemplate(
    Directory templateDir,
    Map<String, String> attributes,
  ) {
    final templateFiles = templateDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.template'))
        .toList();

    if (templateFiles.isEmpty) {
      Logger.warn('No .template files found in $templateDir');
      return;
    }

    final rootPath = Directory.current.path;
    final outputBase = attributes['path'] != null
        ? p.join(rootPath, attributes['path']!)
        : rootPath;

    for (final templateFile in templateFiles) {
      final relativePath = p.relative(
        templateFile.path,
        from: templateDir.path,
      );

      final outputFileName =
          _replaceVariables(relativePath.replaceAll('.template', ''), attributes);

      var content = templateFile.readAsStringSync();
      content = _replaceVariables(content, attributes);

      final outputFile = File(p.join(outputBase, outputFileName));
      outputFile.createSync(recursive: true);
      outputFile.writeAsStringSync(content);

      Logger.info('  ✓ Created: $outputFileName');
    }
  }

  /// Evaluates a condition expression.
  ///
  /// Supports:
  /// - `key == 'value'`
  /// - `key != 'value'`
  /// - `cond1 && cond2` (AND)
  /// - `cond1 || cond2` (OR)
  bool _evaluateCondition(String? condition, Map<String, String> attributes) {
    if (condition == null) return true;

    final trimmed = condition.trim();

    // OR takes lower precedence — split first
    final orParts = trimmed.split('||');
    if (orParts.length > 1) {
      return orParts.any((part) => _evaluateCondition(part.trim(), attributes));
    }

    // AND
    final andParts = trimmed.split('&&');
    if (andParts.length > 1) {
      return andParts
          .every((part) => _evaluateCondition(part.trim(), attributes));
    }

    // Single unit: key == 'value' or key != 'value'
    final neqMatch =
        RegExp(r"^(\w+)\s*!=\s*'?([^']*)'?$").firstMatch(trimmed);
    if (neqMatch != null) {
      final key = neqMatch.group(1)!;
      final expected = neqMatch.group(2)!;
      return (attributes[key] ?? '') != expected;
    }

    final eqMatch =
        RegExp(r"^(\w+)\s*==\s*'?([^']*)'?$").firstMatch(trimmed);
    if (eqMatch != null) {
      final key = eqMatch.group(1)!;
      final expected = eqMatch.group(2)!;
      return (attributes[key] ?? '') == expected;
    }

    Logger.warn("Could not parse scaffold condition: '$trimmed' — treating as true");
    return true;
  }

  /// Applies a named filter to a value (②).
  String _applyFilter(String value, String filter) {
    switch (filter.trim()) {
      case 'snake_case':
        return StringCase.toSnakeCase(value);
      case 'pascal_case':
        return StringCase.toPascalCase(value);
      case 'camel_case':
        return StringCase.toCamelCase(value);
      case 'upper_case':
        return StringCase.toSnakeCase(value).toUpperCase();
      default:
        return value;
    }
  }

  /// Replaces template variables with actual values.
  ///
  /// Supports:
  /// - Pipe filters: `{{name | snake_case}}`, `{{name | pascal_case}}` etc. (②)
  /// - Direct substitution: `{{name}}` → snake_case
  /// - Legacy shorthands: `{{Name}}`, `{{NAME}}`, `{{name_camel}}`
  String _replaceVariables(String content, Map<String, String> attributes) {
    var result = content;

    // ② Pipe filter syntax: {{key | filter}}
    result = result.replaceAllMapped(
      RegExp(r'\{\{(\w+)\s*\|\s*(\w+)\}\}'),
      (match) {
        final key = match.group(1)!;
        final filter = match.group(2)!;
        final value = attributes[key] ?? '';
        return _applyFilter(value, filter);
      },
    );

    // Direct substitution and legacy shorthands
    for (final entry in attributes.entries) {
      final key = entry.key;
      final value = entry.value;

      final snakeCase = StringCase.toSnakeCase(value);
      final pascalCase = StringCase.toPascalCase(value);
      final upperCase = snakeCase.toUpperCase();
      final camelCase = StringCase.toCamelCase(value);

      result = result
          .replaceAll('{{$key}}', snakeCase)
          .replaceAll('{{${key}_pascal}}', pascalCase)
          .replaceAll('{{${key}_upper}}', upperCase)
          .replaceAll('{{${key}_camel}}', camelCase);

      if (key == 'name') {
        result = result
            .replaceAll('{{Name}}', pascalCase)
            .replaceAll('{{NAME}}', upperCase)
            .replaceAll('{{name_camel}}', camelCase);
      }
    }

    return result;
  }

  void _copyDirectory(Directory source, Directory destination) {
    destination.createSync(recursive: true);

    for (final entity in source.listSync()) {
      if (entity is File) {
        entity.copySync(p.join(destination.path, p.basename(entity.path)));
      } else if (entity is Directory) {
        _copyDirectory(
          entity,
          Directory(p.join(destination.path, p.basename(entity.path))),
        );
      }
    }
  }
}

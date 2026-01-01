import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../utils/utils.dart';
import 'commands.dart';

/// Command to generate code from user-defined templates.
/// 사용자 정의 템플릿에서 코드를 생성하는 명령어.
///
/// Usage / 사용법:
/// ```bash
/// flutist scaffold --help
/// flutist scaffold list
/// flutist scaffold <template-name> --name <name>
/// ```
class ScaffoldCommand implements BaseCommand {
  @override
  String get name => 'scaffold';

  @override
  String get description => 'Generate code from templates';

  @override
  void execute(List<String> arguments) {
    // Check for help flag
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

  /// Shows main help message.
  /// 메인 도움말 메시지를 표시합니다.
  void _showHelp() {
    print('''
OVERVIEW: Generates new code based on a template

USAGE: flutist scaffold <template> [options] <subcommand>

ARGUMENTS:
  <template>              Name of template you want to use

OPTIONS:
  --name <name>           Name for the generated files (required)
  --path <path>           Output path (default: current directory)
  -h, --help              Show help information

SUBCOMMANDS:
  list                    Lists available scaffold templates
  help <subcommand>       Show help for a specific subcommand

EXAMPLES:
  flutist scaffold list
  flutist scaffold feature --name login
  flutist scaffold feature --name user_profile --path lib/features
  flutist scaffold layered_feature --name auth --basePath lib/features

TEMPLATE STRUCTURE:
  flutist/templates/
    feature/
      template.yaml         # Template configuration
      bloc.dart.template    # Template file with {{name}} variables
      state.dart.template
      event.dart.template

TEMPLATE VARIABLES:
  {{name}}                snake_case (e.g., user_profile)
  {{Name}}                PascalCase (e.g., UserProfile)  
  {{NAME}}                UPPER_CASE (e.g., USER_PROFILE)
  {{custom}}              Custom attributes from template.yaml

See 'flutist scaffold help <subcommand>' for detailed help.
''');
  }

  /// Shows help for a specific subcommand.
  /// 특정 하위 명령어에 대한 도움말을 표시합니다.
  void _showSubcommandHelp(String subCommand) {
    switch (subCommand) {
      case 'list':
        print('''
OVERVIEW: Lists available scaffold templates

USAGE: flutist scaffold list

DESCRIPTION:
  Displays all templates found in flutist/templates/ directory.
  Each template should contain a template.yaml file with configuration.

TEMPLATE.YAML STRUCTURE:
  description: "Feature template with BLoC pattern"
  attributes:
    - name: name
      required: true
    - name: path
      required: false
      default: "lib/features"
  items:
    - type: file
      path: "{{path}}/{{name}}/{{name}}_bloc.dart"
      templatePath: "bloc.dart.template"
    - type: directory
      path: "{{path}}/{{name}}/assets"
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

  /// Lists all available templates.
  /// 사용 가능한 모든 템플릿을 나열합니다.
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
      Logger.info('      {{name}}_state.dart.template');
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

        // Show template files
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
  /// 템플릿에서 파일을 생성합니다.
  void _generateFromTemplate(String templateName, List<String> arguments) {
    final parser = ArgParser()
      ..addOption(
        'name',
        help: 'Name for the generated files',
        mandatory: true,
      )
      ..addFlag(
        'help',
        abbr: 'h',
        help: 'Show help information',
        negatable: false,
      );

    // Parse known options first
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
  --<attribute> <value>   Custom attribute defined in template.yaml
  -h, --help              Show help information

EXAMPLES:
  flutist scaffold $templateName --name my_feature
  flutist scaffold $templateName --name user --path lib/features

TEMPLATE VARIABLES:
  {{name}}                snake_case version (e.g., user_profile)
  {{Name}}                PascalCase version (e.g., UserProfile)
  {{NAME}}                UPPER_CASE version (e.g., USER_PROFILE)
''');
      return;
    }

    final name = result['name'] as String;

    // Collect all custom attributes
    final attributes = <String, String>{'name': name};

    // Add remaining options as custom attributes
    for (final key in result.options) {
      if (key != 'name' && key != 'help') {
        final value = result[key];
        if (value != null) {
          attributes[key] = value.toString();
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

    _processTemplate(templateName, attributes);

    Logger.success('✅ Scaffold completed!');
  }

  /// Processes a template and generates files.
  /// 템플릿을 처리하고 파일을 생성합니다.
  void _processTemplate(String templateName, Map<String, String> attributes) {
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

    // Check for template.yaml
    final configFile = File(p.join(templateDir.path, 'template.yaml'));

    if (configFile.existsSync()) {
      // Advanced mode: use template.yaml
      _processAdvancedTemplate(templateDir, configFile, attributes);
    } else {
      // Simple mode: process all .template files
      _processSimpleTemplate(templateDir, attributes);
    }
  }

  /// Processes template using template.yaml configuration.
  /// template.yaml 설정을 사용하여 템플릿을 처리합니다.
  void _processAdvancedTemplate(
    Directory templateDir,
    File configFile,
    Map<String, String> attributes,
  ) {
    try {
      final config = loadYaml(configFile.readAsStringSync()) as Map;

      // Validate required attributes
      final configAttributes = config['attributes'] as List?;
      if (configAttributes != null) {
        for (final attr in configAttributes) {
          if (attr is Map) {
            final name = attr['name'] as String;
            final required = attr['required'] == true;
            final defaultValue = attr['default'] as String?;

            if (required && !attributes.containsKey(name)) {
              Logger.error('Missing required attribute: --$name');
              exit(1);
            }

            // Set default value if not provided
            if (!attributes.containsKey(name) && defaultValue != null) {
              attributes[name] = defaultValue;
            }
          }
        }
      }

      // Process items
      final items = config['items'] as List?;
      if (items == null || items.isEmpty) {
        Logger.warn('No items defined in template.yaml');
        return;
      }

      for (final item in items) {
        if (item is! Map) continue;

        final type = item['type'] as String?;

        if (type == 'file') {
          _processFileItem(templateDir, item, attributes);
        } else if (type == 'directory') {
          _processDirectoryItem(templateDir, item, attributes);
        }
      }
    } catch (e) {
      Logger.error('Failed to parse template.yaml: $e');
      exit(1);
    }
  }

  /// Processes a file item from template.yaml.
  /// template.yaml의 파일 항목을 처리합니다.
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

    // Replace variables in output path
    final resolvedOutputPath = _replaceVariables(outputPath, attributes);

    // Read template file
    final templateFile = File(p.join(templateDir.path, templatePath));
    if (!templateFile.existsSync()) {
      Logger.warn('Template file not found: $templatePath');
      return;
    }

    var content = templateFile.readAsStringSync();

    // Replace variables in content
    content = _replaceVariables(content, attributes);

    // Create output file
    final rootPath = Directory.current.path;
    final fullOutputPath = p.join(rootPath, resolvedOutputPath);
    final outputFile = File(fullOutputPath);
    outputFile.createSync(recursive: true);
    outputFile.writeAsStringSync(content);

    Logger.info('  ✓ Created: $resolvedOutputPath');
  }

  /// Processes a directory item from template.yaml.
  /// template.yaml의 디렉토리 항목을 처리합니다.
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

    // Replace variables in output path
    final resolvedOutputPath = _replaceVariables(outputPath, attributes);

    // Source directory
    final sourceDir = Directory(p.join(templateDir.path, sourcePath));
    if (!sourceDir.existsSync()) {
      Logger.warn('Source directory not found: $sourcePath');
      return;
    }

    // Copy directory
    final rootPath = Directory.current.path;
    final fullOutputPath = p.join(rootPath, resolvedOutputPath);
    _copyDirectory(sourceDir, Directory(fullOutputPath));

    Logger.info('  ✓ Copied directory: $resolvedOutputPath');
  }

  /// Processes template in simple mode (no template.yaml).
  /// 단순 모드로 템플릿을 처리합니다 (template.yaml 없음).
  void _processSimpleTemplate(
    Directory templateDir,
    Map<String, String> attributes,
  ) {
    // Get all .template files
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

    for (final templateFile in templateFiles) {
      // Get relative path from template dir
      final relativePath = p.relative(
        templateFile.path,
        from: templateDir.path,
      );

      // Remove .template extension
      final outputFileName = relativePath.replaceAll('.template', '');

      // Replace variables in filename
      final resolvedFileName = _replaceVariables(outputFileName, attributes);

      // Read template content
      var content = templateFile.readAsStringSync();

      // Replace variables in content
      content = _replaceVariables(content, attributes);

      // Create output file
      final outputPath = p.join(rootPath, resolvedFileName);
      final outputFile = File(outputPath);
      outputFile.createSync(recursive: true);
      outputFile.writeAsStringSync(content);

      Logger.info('  ✓ Created: $resolvedFileName');
    }
  }

  /// Replaces template variables with actual values.
  /// 템플릿 변수를 실제 값으로 치환합니다.
  String _replaceVariables(String content, Map<String, String> attributes) {
    var result = content;

    for (final entry in attributes.entries) {
      final key = entry.key;
      final value = entry.value;

      // Generate different case variations
      final snakeCase = _toSnakeCase(value);
      final pascalCase = _toPascalCase(value);
      final upperCase = snakeCase.toUpperCase();
      final camelCase = _toCamelCase(value);

      // Replace all variations
      result = result
          .replaceAll('{{$key}}', snakeCase)
          .replaceAll('{{${key}_pascal}}', pascalCase)
          .replaceAll('{{${key}_upper}}', upperCase)
          .replaceAll('{{${key}_camel}}', camelCase);

      // Special handling for 'name' attribute
      if (key == 'name') {
        result = result
            .replaceAll('{{Name}}', pascalCase)
            .replaceAll('{{NAME}}', upperCase)
            .replaceAll('{{name_camel}}', camelCase);
      }
    }

    return result;
  }

  /// Copies a directory recursively.
  /// 디렉토리를 재귀적으로 복사합니다.
  void _copyDirectory(Directory source, Directory destination) {
    destination.createSync(recursive: true);

    for (final entity in source.listSync()) {
      if (entity is File) {
        final newPath = p.join(destination.path, p.basename(entity.path));
        entity.copySync(newPath);
      } else if (entity is Directory) {
        final newPath = p.join(destination.path, p.basename(entity.path));
        _copyDirectory(entity, Directory(newPath));
      }
    }
  }

  /// Converts any string to snake_case.
  /// 문자열을 snake_case로 변환합니다.
  String _toSnakeCase(String input) {
    var result = input.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );

    if (result.startsWith('_')) {
      result = result.substring(1);
    }

    result = result.replaceAll(' ', '_').replaceAll('-', '_');

    return result.toLowerCase();
  }

  /// Converts snake_case to PascalCase.
  /// snake_case를 PascalCase로 변환합니다.
  String _toPascalCase(String snakeCase) {
    final parts = snakeCase.split('_');
    return parts.map((part) {
      if (part.isEmpty) return part;
      return part[0].toUpperCase() + part.substring(1).toLowerCase();
    }).join('');
  }

  /// Converts snake_case to camelCase.
  /// snake_case를 camelCase로 변환합니다.
  String _toCamelCase(String snakeCase) {
    final parts = snakeCase.split('_');
    if (parts.isEmpty) return snakeCase;

    final first = parts.first.toLowerCase();
    final rest = parts.skip(1).map((part) {
      if (part.isEmpty) return part;
      return part[0].toUpperCase() + part.substring(1).toLowerCase();
    });

    return first + rest.join('');
  }
}

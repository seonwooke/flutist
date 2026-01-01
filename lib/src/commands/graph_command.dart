import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import '../utils/utils.dart';
import 'commands.dart';

/// Command to generate dependency graph.
class GraphCommand implements BaseCommand {
  @override
  String get name => 'graph';

  @override
  String get description => 'Generate dependency graph of modules';

  @override
  void execute(List<String> arguments) {
    final parser = ArgParser()
      ..addOption(
        'format',
        abbr: 'f',
        help: 'Output format',
        allowed: ['mermaid', 'dot', 'ascii'],
        defaultsTo: 'mermaid',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output file path (for mermaid/dot)',
      )
      ..addFlag(
        'open',
        help: 'Open in browser (mermaid only)',
        negatable: false,
      )
      ..addFlag(
        'help',
        abbr: 'h',
        help: 'Show help information',
        negatable: false,
      );

    try {
      final result = parser.parse(arguments);

      if (result['help'] as bool) {
        _showHelp();
        return;
      }

      final format = result['format'] as String;
      final output = result['output'] as String?;
      final open = result['open'] as bool;

      Logger.info('🔍 Analyzing project structure...');

      // Parse project.dart
      final modules = _parseProjectModules();

      Logger.success('Found ${modules.length} modules');

      // Generate graph
      switch (format) {
        case 'mermaid':
          _generateMermaid(modules, output, open);
          break;
        case 'dot':
          _generateDot(modules, output);
          break;
        case 'ascii':
          _generateAscii(modules);
          break;
      }

      Logger.success(' Graph generated!');
    } catch (e) {
      Logger.error('Failed to generate graph: $e');
      exit(1);
    }
  }

  void _showHelp() {
    print('''
OVERVIEW: Generate dependency graph of modules

USAGE: flutist graph [options]

OPTIONS:
  -f, --format <format>   Output format (mermaid, dot, ascii)
                          (default: mermaid)
  -o, --output <path>     Output file path
  --open                  Open in browser (mermaid only)
  -h, --help              Show help information

EXAMPLES:
  flutist graph
  flutist graph --format mermaid --output graph.mmd
  flutist graph --format mermaid --open
  flutist graph --format dot --output graph.dot
  flutist graph --format ascii

FORMATS:
  mermaid     - Mermaid diagram (interactive, web-based)
  dot         - Graphviz DOT format
  ascii       - ASCII art (terminal output)
''');
  }

  /// Parses project.dart and extracts modules.
  List<ModuleNode> _parseProjectModules() {
    final rootPath = Directory.current.path;
    final projectFile = File(p.join(rootPath, 'project.dart'));

    if (!projectFile.existsSync()) {
      Logger.error('project.dart not found');
      exit(1);
    }

    var content = projectFile.readAsStringSync();

    // Remove comments before parsing
    content = _removeComments(content);

    final nodes = <ModuleNode>[];

    // Parse all modules
    final modulePattern = RegExp(
      r'Module\s*\((.*?)\),',
      dotAll: true,
    );

    for (final match in modulePattern.allMatches(content)) {
      final moduleContent = match.group(1)!;

      // Parse name
      final nameMatch = RegExp(r"name:\s*'([^']+)'").firstMatch(moduleContent);
      if (nameMatch == null) continue;
      final name = nameMatch.group(1)!;

      // Parse dependencies
      final dependencies = _parseDependencyNames(moduleContent, 'dependencies');
      final devDependencies =
          _parseDependencyNames(moduleContent, 'devDependencies');
      final modules = _parseModuleReferences(moduleContent);

      nodes.add(ModuleNode(
        name: name,
        dependencies: dependencies,
        devDependencies: devDependencies,
        modules: modules,
      ));
    }

    return nodes;
  }

  /// Removes comments from Dart code.
  String _removeComments(String code) {
    // Remove multi-line comments /* ... */
    code = code.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');

    // Remove single-line comments //
    code = code.replaceAll(RegExp(r'//.*'), '');

    return code;
  }

  List<String> _parseDependencyNames(String content, String fieldName) {
    final names = <String>[];
    final arrayPattern = RegExp(
      '$fieldName:\\s*\\[(.*?)\\]',
      dotAll: true,
    );
    final match = arrayPattern.firstMatch(content);
    if (match == null) return names;

    final arrayContent = match.group(1)!;
    final depPattern = RegExp(r'package\.dependencies\.(\w+)');

    for (final depMatch in depPattern.allMatches(arrayContent)) {
      names.add(depMatch.group(1)!);
    }

    return names;
  }

  List<String> _parseModuleReferences(String content) {
    final names = <String>[];
    final arrayPattern = RegExp(
      r'modules:\s*\[(.*?)\]',
      dotAll: true,
    );
    final match = arrayPattern.firstMatch(content);
    if (match == null) return names;

    final arrayContent = match.group(1)!;
    final modPattern = RegExp(r'package\.modules\.(\w+)');

    for (final modMatch in modPattern.allMatches(arrayContent)) {
      final camelName = modMatch.group(1)!;
      // Convert camelCase to snake_case
      final snakeName = camelName.replaceAllMapped(
        RegExp(r'[A-Z]'),
        (m) => '_${m.group(0)!.toLowerCase()}',
      );
      names.add(snakeName.startsWith('_') ? snakeName.substring(1) : snakeName);
    }

    return names;
  }

  /// Generates Mermaid diagram.
  void _generateMermaid(List<ModuleNode> modules, String? output, bool open) {
    Logger.info('Generating Mermaid diagram...');

    final buffer = StringBuffer();
    buffer.writeln('graph TD');
    buffer.writeln('  %% Module Dependencies');
    buffer.writeln();

    // Define nodes with styling
    for (final module in modules) {
      buffer.writeln('  ${module.name}[${module.name}]');
    }
    buffer.writeln();

    // Define edges (modules only)
    for (final module in modules) {
      for (final mod in module.modules) {
        buffer.writeln('  ${module.name} --> $mod');
      }
    }

    buffer.writeln();
    buffer.writeln('  %% Styling');
    buffer.writeln(
        '  classDef default fill:#e1f5ff,stroke:#01579b,stroke-width:2px');

    final mermaidCode = buffer.toString();

    if (output != null) {
      // Save to file
      final file = File(output);
      file.writeAsStringSync(mermaidCode);
      Logger.success('Saved to: $output');
    } else {
      // Print to console
      print('\n$mermaidCode\n');
    }

    if (open) {
      // Generate HTML and open in browser
      _openMermaidInBrowser(mermaidCode);
    } else {
      Logger.info('');
      Logger.info('View online: https://mermaid.live/');
      Logger.info('Or use: flutist graph --open');
    }
  }

  /// Opens Mermaid diagram in browser.
  void _openMermaidInBrowser(String mermaidCode) {
    Logger.info('Opening in browser...');

    final html = '''
<!DOCTYPE html>
<html>
<head>
  <title>Flutist Dependency Graph</title>
  <script type="module">
    import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs';
    mermaid.initialize({ startOnLoad: true });
  </script>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      margin: 0;
      padding: 20px;
      background: #f5f5f5;
    }
    h1 {
      text-align: center;
      color: #333;
    }
    .container {
      max-width: 1200px;
      margin: 0 auto;
      background: white;
      padding: 30px;
      border-radius: 8px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>📊 Flutist Dependency Graph</h1>
    <div class="mermaid">
$mermaidCode
    </div>
  </div>
</body>
</html>
''';

    final tempDir = Directory.systemTemp.createTempSync('flutist_graph_');
    final htmlFile = File(p.join(tempDir.path, 'graph.html'));
    htmlFile.writeAsStringSync(html);

    // Open in default browser
    if (Platform.isMacOS) {
      Process.run('open', [htmlFile.path]);
    } else if (Platform.isWindows) {
      Process.run('cmd', ['/c', 'start', htmlFile.path]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [htmlFile.path]);
    }

    Logger.success('Opened in browser!');
  }

  /// Generates Graphviz DOT format.
  void _generateDot(List<ModuleNode> modules, String? output) {
    Logger.info('Generating DOT format...');

    final buffer = StringBuffer();
    buffer.writeln('digraph FlutistModules {');
    buffer.writeln('  rankdir=LR;');
    buffer.writeln('  node [shape=box, style=filled, fillcolor=lightblue];');
    buffer.writeln();

    // Edges (modules only)
    for (final module in modules) {
      for (final mod in module.modules) {
        buffer.writeln('  "${module.name}" -> "$mod";');
      }
    }

    buffer.writeln('}');

    final dotCode = buffer.toString();

    if (output != null) {
      final file = File(output);
      file.writeAsStringSync(dotCode);
      Logger.success('Saved to: $output');
      Logger.info('');
      Logger.info('Generate PNG: dot -Tpng $output -o graph.png');
    } else {
      print('\n$dotCode\n');
    }
  }

  /// Generates ASCII art diagram.
  void _generateAscii(List<ModuleNode> modules) {
    Logger.info('Generating ASCII diagram...');
    print('');
    print('📊 Module Dependencies:');
    print('');

    for (final module in modules) {
      if (module.modules.isEmpty) {
        print('┌─ ${module.name}');
        print('│  (no dependencies)');
        print('└─');
        print('');
        continue;
      }

      print('┌─ ${module.name}');
      print('│');
      for (int i = 0; i < module.modules.length; i++) {
        final isLast = i == module.modules.length - 1;
        if (isLast) {
          print('└─> ${module.modules[i]}');
        } else {
          print('├─> ${module.modules[i]}');
        }
      }
      print('');
    }
  }
}

/// Represents a module node in the dependency graph.
class ModuleNode {
  /// Module name.
  final String name;

  /// List of dependency names.
  final List<String> dependencies;

  /// List of dev dependency names.
  final List<String> devDependencies;

  /// List of module dependency names.
  final List<String> modules;

  ModuleNode({
    required this.name,
    required this.dependencies,
    required this.devDependencies,
    required this.modules,
  });
}

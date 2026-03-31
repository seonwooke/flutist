import '../core/core.dart';

/// Result of an architecture rule check.
class CheckResult {
  final CheckSeverity severity;
  final String rule;
  final String message;

  const CheckResult({
    required this.severity,
    required this.rule,
    required this.message,
  });
}

/// Severity level for check results.
enum CheckSeverity { error, ok }

/// Validates architecture rules for module dependencies.
class ArchitectureChecker {
  final Project project;
  final Package package;

  ArchitectureChecker({required this.project, required this.package});

  /// Runs all architecture checks and returns results.
  List<CheckResult> check() {
    final results = <CheckResult>[];
    final compositionRoots = project.options.compositionRoots;

    for (final module in project.modules) {
      results.addAll(_checkImplementationReferences(module, compositionRoots));
      results.addAll(_checkTestingReferences(module));
      results.addAll(_checkExampleReferences(module));
      results.addAll(_checkCleanLayerDirection(module));
    }

    results.addAll(_checkCircularDependencies());

    return results;
  }

  /// Extracts the feature prefix from a layer name.
  /// e.g., 'login_implementation' → 'login', 'login_example' → 'login'
  String _featurePrefix(String name, String suffix) {
    return name.substring(0, name.length - suffix.length);
  }

  /// Checks whether two module names belong to the same feature.
  bool _isSameFeature(String moduleName, String moduleSuffix,
      String depName, String depSuffix) {
    return _featurePrefix(moduleName, moduleSuffix) ==
        _featurePrefix(depName, depSuffix);
  }

  /// Checks that non-composition-root modules don't directly depend on
  /// implementation layers. They should depend on interface layers instead.
  ///
  /// Exceptions: _example and _tests modules may depend on their own
  /// feature's _implementation (Tuist microfeature standard).
  List<CheckResult> _checkImplementationReferences(
    Module module,
    List<String> compositionRoots,
  ) {
    final results = <CheckResult>[];
    final isCompositionRoot = compositionRoots.contains(module.name);

    for (final dep in module.modules) {
      if (!dep.name.endsWith('_implementation')) continue;

      if (isCompositionRoot) {
        results.add(CheckResult(
          severity: CheckSeverity.ok,
          rule: 'implementation_reference',
          message:
              '${module.name} → ${dep.name} (composition root, allowed)',
        ));
      } else if (module.name.endsWith('_example') &&
          _isSameFeature(module.name, '_example', dep.name, '_implementation')) {
        results.add(CheckResult(
          severity: CheckSeverity.ok,
          rule: 'implementation_reference',
          message:
              '${module.name} → ${dep.name} (same feature example, allowed)',
        ));
      } else if (module.name.endsWith('_tests') &&
          _isSameFeature(module.name, '_tests', dep.name, '_implementation')) {
        results.add(CheckResult(
          severity: CheckSeverity.ok,
          rule: 'implementation_reference',
          message:
              '${module.name} → ${dep.name} (same feature tests, allowed)',
        ));
      } else {
        final suggested = dep.name.replaceAll('_implementation', '_interface');
        results.add(CheckResult(
          severity: CheckSeverity.error,
          rule: 'implementation_reference',
          message:
              '${module.name} depends on ${dep.name}\n'
              '  → Should depend on $suggested instead',
        ));
      }
    }

    return results;
  }

  /// Checks that testing layers are only referenced by test or example modules
  /// within the same feature.
  List<CheckResult> _checkTestingReferences(Module module) {
    final results = <CheckResult>[];
    final isTestModule = module.name.endsWith('_tests');
    final isExampleModule = module.name.endsWith('_example');

    for (final dep in module.modules) {
      if (!dep.name.endsWith('_testing')) continue;

      if (isTestModule &&
          _isSameFeature(module.name, '_tests', dep.name, '_testing')) {
        results.add(CheckResult(
          severity: CheckSeverity.ok,
          rule: 'testing_reference',
          message: '${module.name} → ${dep.name} (same feature tests, allowed)',
        ));
      } else if (isExampleModule &&
          _isSameFeature(module.name, '_example', dep.name, '_testing')) {
        results.add(CheckResult(
          severity: CheckSeverity.ok,
          rule: 'testing_reference',
          message:
              '${module.name} → ${dep.name} (same feature example, allowed)',
        ));
      } else {
        results.add(CheckResult(
          severity: CheckSeverity.error,
          rule: 'testing_reference',
          message:
              '${module.name} depends on ${dep.name}\n'
              '  → Testing layers should only be referenced by same feature test/example modules',
        ));
      }
    }

    return results;
  }

  /// Checks that example layers are never referenced as dependencies.
  List<CheckResult> _checkExampleReferences(Module module) {
    final results = <CheckResult>[];

    for (final dep in module.modules) {
      if (!dep.name.endsWith('_example')) continue;

      results.add(CheckResult(
        severity: CheckSeverity.error,
        rule: 'example_reference',
        message:
            '${module.name} depends on ${dep.name}\n'
            '  → Example layers should not be referenced as dependencies',
      ));
    }

    return results;
  }

  /// Checks layer direction for clean modules.
  /// Domain should not depend on Data or Presentation.
  /// Data should not depend on Presentation.
  List<CheckResult> _checkCleanLayerDirection(Module module) {
    final results = <CheckResult>[];

    for (final dep in module.modules) {
      // Domain must not depend on Data or Presentation
      if (module.name.endsWith('_domain')) {
        if (dep.name.endsWith('_data') || dep.name.endsWith('_presentation')) {
          results.add(CheckResult(
            severity: CheckSeverity.error,
            rule: 'clean_layer_direction',
            message:
                '${module.name} depends on ${dep.name}\n'
                '  → Domain layer must not depend on Data or Presentation layers',
          ));
        }
      }

      // Data must not depend on Presentation
      if (module.name.endsWith('_data')) {
        if (dep.name.endsWith('_presentation')) {
          results.add(CheckResult(
            severity: CheckSeverity.error,
            rule: 'clean_layer_direction',
            message:
                '${module.name} depends on ${dep.name}\n'
                '  → Data layer must not depend on Presentation layer',
          ));
        }
      }
    }

    return results;
  }

  /// Detects circular dependencies between modules.
  List<CheckResult> _checkCircularDependencies() {
    final results = <CheckResult>[];

    // Build adjacency map
    final graph = <String, List<String>>{};
    for (final module in project.modules) {
      graph[module.name] = module.modules.map((m) => m.name).toList();
    }

    // DFS cycle detection
    final visited = <String>{};
    final inStack = <String>{};

    void dfs(String node, List<String> path) {
      if (inStack.contains(node)) {
        final cycleStart = path.indexOf(node);
        final cycle = path.sublist(cycleStart)..add(node);
        results.add(CheckResult(
          severity: CheckSeverity.error,
          rule: 'circular_dependency',
          message: 'Circular dependency detected: ${cycle.join(' → ')}',
        ));
        return;
      }

      if (visited.contains(node)) return;

      visited.add(node);
      inStack.add(node);

      for (final dep in graph[node] ?? []) {
        dfs(dep, [...path, node]);
      }

      inStack.remove(node);
    }

    for (final node in graph.keys) {
      if (!visited.contains(node)) {
        dfs(node, []);
      }
    }

    if (results.isEmpty) {
      results.add(const CheckResult(
        severity: CheckSeverity.ok,
        rule: 'circular_dependency',
        message: 'No circular dependencies',
      ));
    }

    return results;
  }
}

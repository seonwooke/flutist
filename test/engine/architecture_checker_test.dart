import 'package:flutist/flutist.dart';
import 'package:test/test.dart';

ArchitectureChecker _checker({
  required List<Module> modules,
  ProjectOptions options = const ProjectOptions(),
}) {
  return ArchitectureChecker(
    project: Project(name: 'test', options: options, modules: modules),
    package: Package(name: 'test', dependencies: [], modules: []),
  );
}

List<CheckResult> _errors(List<CheckResult> results) =>
    results.where((r) => r.severity == CheckSeverity.error).toList();

List<CheckResult> _byRule(List<CheckResult> results, String rule) =>
    results.where((r) => r.rule == rule).toList();

void main() {
  group('Implementation reference check', () {
    test('errors when non-root module depends on implementation', () {
      final checker = _checker(modules: [
        Module(name: 'login', modules: [
          Module(name: 'network_implementation'),
        ]),
      ]);

      final errors = _errors(checker.check());
      expect(errors, hasLength(1));
      expect(errors.first.rule, 'implementation_reference');
    });

    test('allows composition root to depend on implementation', () {
      final checker = _checker(
        modules: [
          Module(name: 'app', modules: [
            Module(name: 'network_implementation'),
          ]),
        ],
        options: const ProjectOptions(compositionRoots: ['app']),
      );

      final errors = _errors(checker.check());
      final implResults =
          _byRule(checker.check(), 'implementation_reference');
      expect(errors, isEmpty);
      expect(implResults.first.severity, CheckSeverity.ok);
    });

    test('allows interface references', () {
      final checker = _checker(modules: [
        Module(name: 'login', modules: [
          Module(name: 'network_interface'),
        ]),
      ]);

      final errors = _errors(checker.check());
      expect(errors, isEmpty);
    });

    test('allows same feature example to depend on implementation', () {
      final checker = _checker(modules: [
        Module(name: 'network_example', modules: [
          Module(name: 'network_implementation'),
        ]),
      ]);

      final implErrors =
          _byRule(_errors(checker.check()), 'implementation_reference');
      expect(implErrors, isEmpty);
    });

    test('allows same feature tests to depend on implementation', () {
      final checker = _checker(modules: [
        Module(name: 'network_tests', modules: [
          Module(name: 'network_implementation'),
        ]),
      ]);

      final implErrors =
          _byRule(_errors(checker.check()), 'implementation_reference');
      expect(implErrors, isEmpty);
    });

    test('errors when example depends on different feature implementation',
        () {
      final checker = _checker(modules: [
        Module(name: 'login_example', modules: [
          Module(name: 'network_implementation'),
        ]),
      ]);

      final implErrors =
          _byRule(_errors(checker.check()), 'implementation_reference');
      expect(implErrors, hasLength(1));
    });

    test('errors when tests depends on different feature implementation', () {
      final checker = _checker(modules: [
        Module(name: 'login_tests', modules: [
          Module(name: 'network_implementation'),
        ]),
      ]);

      final implErrors =
          _byRule(_errors(checker.check()), 'implementation_reference');
      expect(implErrors, hasLength(1));
    });
  });

  group('Testing reference check', () {
    test('errors when non-test module depends on testing', () {
      final checker = _checker(modules: [
        Module(name: 'login_data', modules: [
          Module(name: 'network_testing'),
        ]),
      ]);

      final errors = _errors(checker.check());
      expect(errors, hasLength(1));
      expect(errors.first.rule, 'testing_reference');
    });

    test('allows test module to depend on same feature testing', () {
      final checker = _checker(modules: [
        Module(name: 'network_tests', modules: [
          Module(name: 'network_testing'),
        ]),
      ]);

      final testingErrors =
          _byRule(_errors(checker.check()), 'testing_reference');
      expect(testingErrors, isEmpty);
    });

    test('allows example module to depend on same feature testing', () {
      final checker = _checker(modules: [
        Module(name: 'network_example', modules: [
          Module(name: 'network_testing'),
        ]),
      ]);

      final testingErrors =
          _byRule(_errors(checker.check()), 'testing_reference');
      expect(testingErrors, isEmpty);
    });

    test('errors when tests depends on different feature testing', () {
      final checker = _checker(modules: [
        Module(name: 'login_tests', modules: [
          Module(name: 'network_testing'),
        ]),
      ]);

      final testingErrors =
          _byRule(_errors(checker.check()), 'testing_reference');
      expect(testingErrors, hasLength(1));
    });

    test('errors when example depends on different feature testing', () {
      final checker = _checker(modules: [
        Module(name: 'login_example', modules: [
          Module(name: 'network_testing'),
        ]),
      ]);

      final testingErrors =
          _byRule(_errors(checker.check()), 'testing_reference');
      expect(testingErrors, hasLength(1));
    });

    test('errors when implementation depends on same feature testing', () {
      // _implementation must never depend on _testing (production code must
      // not import test utilities, even from the same feature)
      final checker = _checker(modules: [
        Module(name: 'network_implementation', modules: [
          Module(name: 'network_testing'),
        ]),
      ]);

      final testingErrors =
          _byRule(_errors(checker.check()), 'testing_reference');
      expect(testingErrors, hasLength(1));
      expect(testingErrors.first.message, contains('network_implementation'));
    });

    test('errors when implementation depends on different feature testing', () {
      final checker = _checker(modules: [
        Module(name: 'network_implementation', modules: [
          Module(name: 'auth_testing'),
        ]),
      ]);

      final testingErrors =
          _byRule(_errors(checker.check()), 'testing_reference');
      expect(testingErrors, hasLength(1));
    });
  });

  group('Example reference check', () {
    test('errors when any module depends on example', () {
      final checker = _checker(modules: [
        Module(name: 'login', modules: [
          Module(name: 'network_example'),
        ]),
      ]);

      final errors = _errors(checker.check());
      expect(errors, hasLength(1));
      expect(errors.first.rule, 'example_reference');
    });
  });

  group('Clean layer direction check', () {
    test('errors when domain depends on data', () {
      final checker = _checker(modules: [
        Module(name: 'login_domain', modules: [
          Module(name: 'login_data'),
        ]),
      ]);

      final errors = _errors(checker.check());
      expect(errors, hasLength(1));
      expect(errors.first.rule, 'clean_layer_direction');
    });

    test('errors when domain depends on presentation', () {
      final checker = _checker(modules: [
        Module(name: 'login_domain', modules: [
          Module(name: 'login_presentation'),
        ]),
      ]);

      final errors = _errors(checker.check());
      expect(errors, hasLength(1));
      expect(errors.first.rule, 'clean_layer_direction');
    });

    test('errors when data depends on presentation', () {
      final checker = _checker(modules: [
        Module(name: 'login_data', modules: [
          Module(name: 'login_presentation'),
        ]),
      ]);

      final errors = _errors(checker.check());
      expect(errors, hasLength(1));
      expect(errors.first.rule, 'clean_layer_direction');
    });

    test('allows presentation to depend on data', () {
      final checker = _checker(modules: [
        Module(name: 'login_presentation', modules: [
          Module(name: 'login_data'),
        ]),
      ]);

      final dirErrors =
          _byRule(_errors(checker.check()), 'clean_layer_direction');
      expect(dirErrors, isEmpty);
    });
  });

  group('Circular dependency check', () {
    test('detects simple cycle A → B → A', () {
      final checker = _checker(modules: [
        Module(name: 'a', modules: [Module(name: 'b')]),
        Module(name: 'b', modules: [Module(name: 'a')]),
      ]);

      final cycleErrors =
          _byRule(_errors(checker.check()), 'circular_dependency');
      expect(cycleErrors, isNotEmpty);
      expect(cycleErrors.first.message, contains('→'));
    });

    test('detects 3-node cycle A → B → C → A', () {
      final checker = _checker(modules: [
        Module(name: 'a', modules: [Module(name: 'b')]),
        Module(name: 'b', modules: [Module(name: 'c')]),
        Module(name: 'c', modules: [Module(name: 'a')]),
      ]);

      final cycleErrors =
          _byRule(_errors(checker.check()), 'circular_dependency');
      expect(cycleErrors, isNotEmpty);
    });

    test('no cycle in linear chain', () {
      final checker = _checker(modules: [
        Module(name: 'a', modules: [Module(name: 'b')]),
        Module(name: 'b', modules: [Module(name: 'c')]),
        Module(name: 'c', modules: []),
      ]);

      final cycleResults =
          _byRule(checker.check(), 'circular_dependency');
      expect(cycleResults, hasLength(1));
      expect(cycleResults.first.severity, CheckSeverity.ok);
    });

    test('handles empty project', () {
      final checker = _checker(modules: []);

      final cycleResults =
          _byRule(checker.check(), 'circular_dependency');
      expect(cycleResults, hasLength(1));
      expect(cycleResults.first.severity, CheckSeverity.ok);
    });

    test('handles module with no dependencies', () {
      final checker = _checker(modules: [
        Module(name: 'a', modules: []),
        Module(name: 'b', modules: []),
      ]);

      final cycleResults =
          _byRule(checker.check(), 'circular_dependency');
      expect(cycleResults.first.severity, CheckSeverity.ok);
    });
  });

  group('Circular dependency edge cases', () {
    test('detects self-referencing cycle', () {
      final checker = _checker(modules: [
        Module(name: 'a', modules: [Module(name: 'a')]),
      ]);

      final cycleErrors =
          _byRule(_errors(checker.check()), 'circular_dependency');
      expect(cycleErrors, isNotEmpty);
    });

    test('detects disjoint cycles independently', () {
      final checker = _checker(modules: [
        Module(name: 'a', modules: [Module(name: 'b')]),
        Module(name: 'b', modules: [Module(name: 'a')]),
        Module(name: 'c', modules: [Module(name: 'd')]),
        Module(name: 'd', modules: [Module(name: 'c')]),
      ]);

      final cycleErrors =
          _byRule(_errors(checker.check()), 'circular_dependency');
      expect(cycleErrors.length, greaterThanOrEqualTo(2));
    });

    test('no false positive on diamond dependency', () {
      // A → B, A → C, B → D, C → D (no cycle)
      final checker = _checker(modules: [
        Module(name: 'a', modules: [Module(name: 'b'), Module(name: 'c')]),
        Module(name: 'b', modules: [Module(name: 'd')]),
        Module(name: 'c', modules: [Module(name: 'd')]),
        Module(name: 'd', modules: []),
      ]);

      final cycleResults =
          _byRule(checker.check(), 'circular_dependency');
      expect(cycleResults, hasLength(1));
      expect(cycleResults.first.severity, CheckSeverity.ok);
    });
  });

  group('Implementation reference edge cases', () {
    test('custom compositionRoots override', () {
      final checker = _checker(
        modules: [
          Module(name: 'di_module', modules: [
            Module(name: 'network_implementation'),
          ]),
        ],
        options: const ProjectOptions(compositionRoots: ['di_module']),
      );

      final errors = _errors(checker.check());
      expect(errors, isEmpty);
    });

    test('empty compositionRoots means no exceptions', () {
      final checker = _checker(
        modules: [
          Module(name: 'app', modules: [
            Module(name: 'network_implementation'),
          ]),
        ],
        options: const ProjectOptions(compositionRoots: []),
      );

      final errors = _errors(checker.check());
      expect(errors, hasLength(1));
      expect(errors.first.rule, 'implementation_reference');
    });

    test('ignores non-implementation suffixes', () {
      final checker = _checker(modules: [
        Module(name: 'login', modules: [
          Module(name: 'network_interface'),
          Module(name: 'utils'),
        ]),
      ]);

      final implErrors =
          _byRule(_errors(checker.check()), 'implementation_reference');
      expect(implErrors, isEmpty);
    });
  });

  group('Combined checks', () {
    test('reports multiple violations', () {
      final checker = _checker(modules: [
        Module(name: 'login_domain', modules: [
          Module(name: 'login_data'),
          Module(name: 'network_implementation'),
        ]),
      ]);

      final errors = _errors(checker.check());
      expect(errors.length, greaterThanOrEqualTo(2));
    });

    test('clean project passes all checks', () {
      final checker = _checker(modules: [
        Module(name: 'app', modules: [
          Module(name: 'network_interface'),
        ]),
        Module(name: 'network_interface', modules: []),
      ]);

      final errors = _errors(checker.check());
      expect(errors, isEmpty);
    });
  });
}

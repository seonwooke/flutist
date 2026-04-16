// ignore_for_file: unused_import

import 'package:flutist/flutist.dart';

import 'flutist/flutist_gen.dart';
import 'package.dart';

/// Project configuration — defines all modules and their relationships.
///
/// Modules are declared as individual layer packages.
/// Layer dependencies are wired here explicitly (auto-wired by `flutist create`).
///
/// After modifying, run `flutist generate` to sync pubspec.yaml files.
final project = Project(
  name: 'my_flutter_project',
  options: const ProjectOptions(),
  modules: [
    // ─── App shell (simple) ───────────────────────────────────────────────
    Module(
      name: 'app',
      modules: [
        package.modules.authPresentation,
        package.modules.networkInterface,
      ],
    ),

    // ─── auth — Clean Architecture ────────────────────────────────────────
    //
    // Direction: presentation → data → domain
    // Created with: flutist create --path features --name auth --options clean

    Module(
      name: 'auth_domain',
      dependencies: [],
      devDependencies: [
        package.dependencies.test,
      ],
      modules: [],
    ),

    Module(
      name: 'auth_data',
      dependencies: [
        package.dependencies.http,
      ],
      devDependencies: [
        package.dependencies.test,
        package.dependencies.mockito,
      ],
      modules: [
        package.modules.authDomain,
        package.modules.networkInterface,
      ],
    ),

    Module(
      name: 'auth_presentation',
      dependencies: [],
      devDependencies: [
        package.dependencies.test,
      ],
      modules: [
        package.modules.authData,
      ],
    ),

    // ─── network — Lite Architecture ──────────────────────────────────────
    //
    // Direction: implementation/testing → interface
    //            tests → implementation + testing
    // Created with: flutist create --path lib --name network --options lite

    Module(
      name: 'network_interface',
      dependencies: [],
      modules: [],
    ),

    Module(
      name: 'network_implementation',
      dependencies: [
        package.dependencies.http,
      ],
      modules: [
        package.modules.networkInterface,
      ],
    ),

    Module(
      name: 'network_testing',
      modules: [
        package.modules.networkInterface,
      ],
    ),

    Module(
      name: 'network_tests',
      devDependencies: [
        package.dependencies.test,
        package.dependencies.mockito,
      ],
      modules: [
        package.modules.networkImplementation,
        package.modules.networkTesting,
      ],
    ),

    // ─── utils (simple) ───────────────────────────────────────────────────
    Module(
      name: 'utils',
      dependencies: [],
      modules: [],
    ),
  ],
);

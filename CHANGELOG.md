# Changelog

All notable changes to Flutist will be documented in this file.

## [3.2.0] - 2026-08-30

### ✨ Features

- **Local and Git packages can be declared in `package.dart`**
  - `Dependency` could only describe a package published on pub.dev:
    a name and a version constraint. A package sitting on disk or
    living in a Git repository had no representation, so the only way
    to use one was to edit a module's `pubspec.yaml` by hand, and
    that edit did not survive the next `flutist generate` (see the
    fix below).
  - Two new forms sit alongside the existing one:
    ```dart
    Dependency.path(name: 'design_system', path: 'shared/design_system'),
    Dependency.git(
      name: 'analytics',
      url: 'https://github.com/acme/analytics.git',
      ref: 'main',
      path: 'packages/analytics',
    ),
    ```
    `ref` and `path` are optional on `Dependency.git`; omitting both
    emits pub's short `git: <url>` form.
  - Reference them from `project.dart` exactly like any other
    dependency (`package.dependencies.designSystem`) and run
    `flutist generate`.
  - A `Dependency.path` is written **relative to `package.dart`**, not
    relative to the module consuming it. Flutist re-anchors the path
    for each module when writing its `pubspec.yaml`, so a single
    declaration yields `../shared/design_system` for a top-level
    module and `../../../shared/design_system` for a nested one. This
    is the part that hand-editing gets wrong most often.
  - `Dependency.version` is now nullable, since it is meaningless for
    the two new kinds. The pub.dev constructor still requires it, so
    existing `package.dart` files need no changes.

### 🐛 Bug Fixes

- **`flutist generate` no longer discards hand-written dependencies**
  - Generation rebuilt each module's `dependencies` section from
    scratch and kept only entries carrying an `sdk:` key. Every other
    pre-existing entry was deleted without so much as a warning. A
    local `path:` dependency, a `git:` dependency, or a package added
    straight to a module's `pubspec.yaml` vanished on the next
    `flutist generate`.
  - Worse, `dev_dependencies` behaved the opposite way and preserved
    unmanaged entries, so the two halves of the same file followed
    contradictory rules.
  - Preservation is now decided by ownership instead of by shape. A
    name declared in `package.dart`, or belonging to a module in the
    workspace, is Flutist's to manage. Anything else belongs to the
    user and is written back untouched. Both sections follow the rule.
  - Removing a dependency from `package.dart` still clears it from
    every module, so `pub delete` is unaffected.

- **`flutist pub delete` works on path and git dependencies**
  - The package.dart lookup assumed a single-line
    `Dependency(name: '...', version: '...')` with the arguments in
    that exact order, so a path or git declaration was reported as
    "not found in package.dart" and could not be deleted. Lookup now
    matches the declaration head and reads the argument list by paren
    matching, which handles any argument order and the multi-line git
    form.
  - After deletion, the dependency also lingered in every module's
    `pubspec.yaml`: `generate` reads `package.dart` to decide what it
    owns, and the entry had just been removed from it, so the leftover
    looked user-authored and was preserved. `pub delete` now tells
    `generate` which names it removed. The same gap affected
    `dev_dependencies` previously.

- **Commented-out declarations are no longer parsed as real ones**
  - The `package.dart` parser matched `Dependency` and `Module`
    declarations anywhere in the file, comments included. Because
    `flutist init` writes its `package.dart` with commented examples,
    every project created by Flutist carried phantom `intl` and `test`
    dependencies. They showed up as accessors in `flutist_gen.dart`,
    and referencing one produced a `pubspec.yaml` entry pinned to the
    example's made-up version.
  - This also collided with the ownership rule above: the phantom
    `test` entry made `test` look like a name Flutist manages, so a
    module with a hand-written `test:` dev_dependency would have had
    it removed.
  - Line comments are now masked before parsing. The mask is
    quote-aware, so the `//` inside a git URL survives.

- **`pub delete` removes the declaration, not a commented example**
  - The `package.dart` lookup scanned raw text and stopped at the
    first textual match. Deleting a package that also appeared in one
    of the commented examples removed the comment and left the real
    declaration untouched, while still reporting success and cleaning
    `project.dart` and every module `pubspec.yaml`. The command that
    exists to keep the workspace consistent left it inconsistent.

- **Dependencies missing from `package.dart` are reported**
  - A dependency referenced in `project.dart` but not declared in
    `package.dart` was skipped silently, leaving the user to work out
    why it never appeared in the generated `pubspec.yaml`. Generation
    now names it.

- **`flutist generate` no longer drops entries silently**
  - A dependency Flutist owns but that `project.dart` does not
    reference is removed from a module's `pubspec.yaml`. That is by
    design, since `project.dart` is the source of truth for what each
    module depends on, but generation did it without a word. The only
    signal was the entry being gone, which reads as data loss.
  - Each dropped name is now reported along with the declaration that
    would keep it, and the two cases are distinguished: a workspace
    module points at `package.modules.x` in the module's `modules`
    list, a `package.dart` dependency at `package.dependencies.x` in
    its `dependencies` list.
  - Removing an entire `dev_dependencies` section is covered too. That
    was the same gap one level up: a section holding nothing but
    Flutist-owned names vanished without comment.
  - Two cases stay quiet on purpose. Names handed over by `pub delete`
    were already reported by that command. Names `project.dart` does
    declare were dropped for another reason, such as a module missing
    from the workspace, which generation reports on its own; pointing
    the user at a declaration that already exists would send them to
    the wrong file.

### 🧹 Internal

- The `package.dart` dependency parser reads named arguments
  individually rather than matching one fixed argument order, so
  `Dependency(version: '^1.0.0', name: 'http')` parses correctly. A
  declaration missing a required argument is reported and skipped
  instead of silently disappearing.

### 📚 Documentation

- **What `flutist generate` touches is now written down**
  - Which entries in a module's `pubspec.yaml` survive generation was
    answerable only from the source. README gains a table covering
    what is kept, what is overwritten, and what is removed, and
    `flutist help generate` carries the same summary.
  - Both state the two limits that were previously undocumented:
    comments inside `dependencies` and `dev_dependencies` do not
    survive, since those sections are re-serialized in full, and blank
    lines are normalized to one between sections.

### 🧪 Tests

- **Coverage for pubspec.yaml generation**
  - Ownership-based preservation is the guarantee that lets a team
    keep a local path package or a Git fork wired up by hand, and the
    `commands/` directory had no tests at all. The whole pipeline was
    resting on manual verification.
  - Both halves of the rule are now covered: sdk, hand-written `path:`,
    `git:` and hosted entries and non-dependency sections survive,
    while a name declared in `package.dart` is rewritten from it. Also
    covered are `path:` re-anchoring at two nesting depths, both git
    emission forms, idempotence across runs, and the drop warnings
    including their two silent cases.

## [3.1.0] - 2026-05-19

### ✨ Features

- **`flutist pub delete <pkg>` — remove dependencies declaratively**
  - `flutist pub add` had no inverse. Removing a dependency meant
    hand-editing `package.dart`, hunting down every
    `package.dependencies.xxx` line in `project.dart`, regenerating
    `flutist_gen.dart`, and finally running `flutist generate` to
    clean up the per-module `pubspec.yaml` files. Easy to get wrong;
    the smallest mistake left dangling references that broke the next
    `flutist generate`.
  - `pub delete` does the whole round trip in one shot. It scans
    `project.dart` for usages, prints the full plan (the
    `Dependency` entry that will leave `package.dart` plus every
    module reference that will be cleaned), and waits for a y/n
    confirmation. After the user approves it rewrites both files,
    regenerates `flutist_gen.dart`, and runs the full generate
    pipeline so every module `pubspec.yaml` is back in sync without
    a follow-up command.
  - Accepts one or more package names: `flutist pub delete http dio
    bloc`. Each is validated against `package.dart` up front;
    requesting an unknown name aborts before any file is touched.
  - `--dry-run` prints the plan and exits without writing.
    `-y` / `--yes` skips the confirmation prompt for scripts.
  - The reference cleanup handles both list shapes users actually
    write: own-line entries in a multi-line list and inline lists
    like `dependencies: [package.dependencies.flutterBloc]`.
    Surrounding indentation and adjacent items keep their formatting.
  - `help` text for `pub` is rewritten to document both
    subcommands (`add`, `delete`) and the new flags.

## [3.0.6] - 2026-05-10

### 🐛 Bug Fixes

- **`flutist pub add --version` now actually pins the version**
  - The `pub add` help advertised `--version <version>` and even showed
    `flutist pub add provider --version ^2.0.0` as an example, but the
    flag was never parsed. Arguments were forwarded to `dart pub add`
    verbatim, so `--version` reached `dart pub add` (which does not
    accept it) and the command failed with an unrelated "could not find
    an option" error from the underlying tool.
  - `--version` (and `--version=<value>`) is now parsed up front. It
    must apply to a single package; combining it with multiple packages
    is rejected with a clear message. The constraint is forwarded to
    `dart pub add` using its native `package:constraint` syntax.
  - The help text for `pub add` was also rewritten to document the
    multi-package form (`flutist pub add http dio bloc`) that already
    worked but was undocumented.

### 🧹 Internal

- **Removed unreachable `ScaffoldType.custom`**
  - The enum value was accepted by `ScaffoldType.fromString` and had
    switch handlers in `create_command` and `create_templates`, but the
    `flutist create --options` argparser only allowed `clean`, `micro`,
    or `lite`. The value was unreachable from the CLI, and the
    init-generated README already dropped it in 3.0.4. The enum value
    and its dead handlers are now gone.

## [3.0.5] - 2026-05-03

### 🐛 Bug Fixes

- **`flutist <command> --help` / `-h` now works for every command**
  - The general help screen advertised `flutist <command> --help` as a
    way to see per-command usage, but only `graph`, `test`, and
    `scaffold` actually wired the flag into their argparser. Running
    `flutist create --help`, `flutist generate --help`, `flutist check
    --help`, or `flutist pub --help` returned a "Could not find an
    option named --help" error instead of help text.
  - Worse, `flutist init --help` did not error at all. Because `init`
    skips argparser and reads from stdin, the flag was silently ignored
    and the command dropped into the interactive new-project prompt,
    so a user looking for help could accidentally start scaffolding a
    project in the current directory.
  - All five commands (`init`, `create`, `generate`, `check`, `pub`)
    now short-circuit on `--help` or `-h` and delegate to the existing
    `HelpCommand`, matching the behavior of `graph`, `test`, and
    `scaffold`.

## [3.0.4] - 2026-04-25

### 🐛 Bug Fixes

- **`flutist help create`: corrected mismatch with argparser**
  - The help text listed `simple` as a valid `--options` value and marked
    `--options` as required, but the argparser only accepts
    `clean|micro|lite` and treats the flag as optional. Running
    `flutist create --options simple` would fail despite the help
    advertising it.
  - The help now reflects the actual CLI surface: `--options` is shown as
    optional, `simple` is removed from the listed types, and a note
    explains that omitting `--options` produces a single package. The
    section was also renamed from "MODULE TYPES" to "SCAFFOLD TYPES" to
    match the internal `ScaffoldType` enum and the README.

- **`flutist help check`: clarified Clean Architecture direction rule**
  - The rule was previously phrased as
    "Clean module layers must follow direction: Presentation → Data →
    Domain", which implied a strict chain. The checker actually only
    forbids reverse arrows: `_domain` must not depend on
    `_data`/`_presentation`, and `_data` must not depend on
    `_presentation`. Both the parallel auto-wired pattern
    (`presentation → domain`, `data → domain`) and the chain pattern are
    valid. The help now states the precise rule.

### 📝 Documentation

- **`flutist init`-generated README: removed unsupported `custom` type**
  - The README written by `flutist init` listed `custom` as a module type,
    but `flutist create --options custom` is rejected by the argparser.
    New users following the README hit an immediate dead end. The entry is
    removed.

- **Documentation links now use the stable production alias**
  - The `documentation:` field in `pubspec.yaml` and two README links
    embedded a Vercel deployment hash
    (`flutist-1pn8eqs9s-seonwookes-projects.vercel.app`), which is tied to
    a specific deployment and would break if that deployment were archived
    or rotated. Switched to the stable production alias
    `flutist-web.vercel.app`. CHANGELOG entries that reference the old URL
    in past releases were left untouched to preserve history.

## [3.0.3] - 2026-04-24

### 🔧 Chore

- **Automated GitHub Releases on tag push**
  - Added `.github/workflows/release.yml` that creates a GitHub Release with
    auto-generated notes whenever a `v*` tag is pushed.
  - Version bumps now produce a visible entry on the repository's Releases page.

- **Updated `documentation:` link in `pubspec.yaml`**
  - The "Documentation" link on pub.dev now points to the dedicated docs site
    (`https://flutist-1pn8eqs9s-seonwookes-projects.vercel.app/`) instead of
    the DeepWiki page.

## [3.0.2] - 2026-04-19

### 🐛 Bug Fixes

- **`flutist init` on existing projects no longer produces an invalid `workspace: []`**
  - When migrating an existing project, `init` previously inserted an empty `workspace: []`
    into `pubspec.yaml`, which caused `flutter pub get` to fail.
  - The `workspace` section is now left untouched during migration and is created on
    demand when the first module is added via `flutist create`.

- **`flutist create` now creates the `workspace` section if it's missing**
  - Previously, running `flutist create` right after a migration-mode `init`
    (or on any project without a `workspace:` section) failed with
    `Failed to traverse to subpath (workspace)`.
  - `CreateCommand` now falls back to creating a block-style `workspace` list
    with the new module when the section is absent.

- **`flutist create --path .` produces clean workspace entries**
  - Workspace entries are now normalized via POSIX path normalization,
    so `--name app --path .` yields `app` instead of `./app`.

- **`flutist generate` now surfaces a clear warning when `workspace:` is missing or malformed**
  - Previously, a missing or non-list `workspace:` caused `_buildModulePathMap`
    to silently return an empty map, producing misleading per-module
    "Could not find module" warnings while still reporting success.
  - An upfront warning is now emitted, and unparseable module pubspec.yaml files
    are logged instead of silently skipped.

- **New-project `pubspec.yaml` template now seeds `workspace:` with `- app`**
  - The template previously rendered `workspace:` with a null value and relied
    on a downstream catch-and-create fallback. The template now emits the
    section as a proper block list, removing the fragility.

- **`flutist init` now exits with code 1 on failure**
  - Previously, the top-level `catch` in `InitCommand.execute` only logged the
    error and let the process exit with code 0, so CI/scripts could not detect
    init failures. It now matches the other commands (`create`, `generate`,
    `test`, `scaffold`) and calls `exit(1)`.

- **`flutist scaffold` now strips only the trailing `.template` suffix**
  - The previous `replaceAll('.template', '')` removed every occurrence in the
    path, so a file named `widget.template.dart.template` would be written as
    `widget..dart`. The suffix is now stripped via `RegExp(r'\.template$')`.

- **`flutist test` no longer truncates failure output**
  - `_runModuleTest` previously attached `listen` callbacks to stdout/stderr
    and read the buffers immediately after `process.exitCode`, racing the
    transform pipeline and sometimes cutting off the last lines of stack
    traces. The streams are now drained via `.join()` futures that are awaited
    after the process exits, guaranteeing full output capture.

### 📝 Documentation

- **Docs badge now links to the official docs site**
  - The README `Docs` badge points to `https://flutist-1pn8eqs9s-seonwookes-projects.vercel.app/docs`
    instead of the previous deepwiki URL.

## [3.0.1] - 2026-04-16

### 📝 Documentation

- **README overhaul**: Rewrote and expanded README with full documentation site content
  - Added Core Values section (Declarative, Single Source, Rules as Code)
  - Added Core Files section (`package.dart`, `project.dart`, `flutist_gen.dart`)
  - Added Architecture Validation section (5 rules + `strictMode`/`compositionRoots` config)
  - Expanded Project Structure with `packages/` directory example
  - Fixed Commands table bold+code formatting (`**\`command\`**`)
  - Added "Learn more about Flutist!" link to docs site

## [3.0.0] - 2026-04-13

### 💥 Breaking Changes

- **`ModuleType` → `ScaffoldType` rename**
  - `ModuleType` enum is removed. Use `ScaffoldType` internally (create-time only).
  - `ScaffoldType` is never written to `project.dart` or `package.dart`.

- **`Module.type` field removed**
  - The `type:` field in `Module(...)` is no longer valid.
  - If `project.dart` contains `type: ModuleType.xxx`, parsing will fail with a migration error.
  - **Migration**: Remove all `type: ModuleType.xxx,` lines from `project.dart`.

- **`--options simple` removed from `flutist create`**
  - Omitting `--options` now creates a single package by default (was `--options simple`).
  - `--options` accepts `clean`, `micro`, `lite` only.

### ✨ New Features

- **B6: Layer dependency auto-wiring on `flutist create`**
  - Layer packages are automatically wired in `project.dart` based on scaffold type:
    - `clean`: `presentation → domain`, `data → domain` (both independently depend on domain)
    - `micro`: `implementation/testing → interface`, `tests/example → implementation + testing`
    - `lite`: `implementation/testing → interface`, `tests → implementation + testing`

- **`flutist scaffold` enhancement**
  - **Custom attribute CLI**: Attributes defined in `template.yaml` are now passed via `--<attribute> value`
  - **Filter system**: `{{name | snake_case}}`, `{{name | pascal_case}}`, `{{name | camel_case}}`, `{{name | upper_case}}`
    (legacy `{{Name}}`, `{{NAME}}` shorthands are still supported)
  - **Conditional generation**: Items support `if: "attribute == 'value'"` to skip files conditionally
  - **`string` item type**: Define file contents inline in `template.yaml` without an external `.template` file
  - **`--path` fix in simple mode**: `--path` is now respected as the output base directory

- **D3: `flutter test` vs `dart test` auto-detection**
  - `flutist test` automatically selects `flutter test` or `dart test` per module.
  - Detects Flutter packages by checking the module and its path dependencies recursively — test-only packages that depend on Flutter implementation packages are correctly identified without requiring `flutter_test` in their own `pubspec.yaml`.

- **Architecture Checker: explicit tests for `_implementation → _testing` rule**
  - Added tests verifying that `_implementation` must never depend on `_testing`, even within the same feature (enforced via the existing `testing_reference` rule).

### 🐛 Fixed

- **`flutist init`**: Removed `type: ModuleType.simple` from generated `project.dart` template
- **`flutist init`**: Removed hardcoded example dependencies (`intl`, `test`) from `package.dart` template
- **`flutist init`**: Added `flutter: uses-material-design: true` to root `pubspec.yaml` — without this, `Icons.*` render as `?` at runtime
- **`flutist scaffold`**: Example template replaced with neutral StatelessWidget/StatefulWidget (no `flutter_bloc` dependency)

### 🔄 Migration from 2.x

Remove `type:` from all `Module(...)` entries in `project.dart`:

```dart
// Before (2.x)
Module(
  name: 'auth_domain',
  type: ModuleType.clean,   // ← remove this line
  dependencies: [],
  modules: [],
),

// After (3.0.0)
Module(
  name: 'auth_domain',
  dependencies: [],
  modules: [],
),
```

If `type:` remains, `flutist generate` / `flutist check` will print a clear error
pointing to this CHANGELOG.

---

## [2.1.0] - 2026-04-07

### ✨ New Features

- **`flutist init`: New/existing project selection**
  - Choose between new project creation or existing project migration during init
  - Existing project: skip app module creation, skip workspace app entry, generate empty project.dart/package.dart
- **`flutist pub add`: Multi-package support**
  - Add multiple packages at once with `flutist pub add http dio`
- **Template usage guide comments for existing projects**
  - Added 3-step workflow comments and examples to `project.dart` and `package.dart`

### 🐛 Fixed

- **`flutist create`**: Fixed missing module name in simple module path (`packages/` → `packages/core`)
- **`flutist create`**: Warn and exit when layer module name suffix is entered redundantly
- **`flutist create`**: Warn and exit when last path segment matches the module name (nested path detection)
- **`flutist create`**: Auto-generate barrel file (`lib/module_name.dart`) when creating a module
- **`flutist generate`**: Cross-path module dependency resolution — removed hardcoded basePaths, now resolved dynamically via workspace scan
- **`flutist generate`**: Preserve all SDK dependencies including `flutter`, `flutter_localizations`, etc. (previously only `flutter` was preserved)
- **`flutist init`**: Do not overwrite `lib/main.dart` if it already exists
- **`flutist init`**: Do not overwrite `analysis_options.yaml` if it already exists
- **`flutist init`**: Workspace entries are now added in block style (`- path/to/module`)
- **`flutist pub add`**: Fixed format corruption where `],` was appended on the same line on repeated runs
- **`flutist pub add`**: Fixed duplicate output of `Generated flutist_gen.dart` message
- **`flutist scaffold`**: Fixed bug where `--path` option existed in docs but did not actually work
- **`flutist test`**: Print full stdout/stderr without keyword filtering on failure
- **Architecture Checker**: Allow `_example` and `_tests` of the same feature to depend on `_implementation` and `_testing` (Tuist microfeature standard)

### 🔧 Changed

- **`strictMode` behavior change**: Architecture violations are always detected and reported even when `strictMode: false`. `strictMode` only controls whether to abort on violations
  - `true` (default): Abort generate/check when violations are found (exit 1)
  - `false`: Print violations and continue (intended for migration transition period)

### 📝 Documentation

- README: Added notes on SDK dependencies and Flutter build configuration
- README: Documented directory structure per module type
- README: Documented init workflow for new and existing projects

---

## [2.0.0] - 2026-03-30

### 🚀 Breaking Changes

- **Module Type Renaming**:
  - `feature` → `clean` (Clean Architecture: Domain / Data / Presentation)
  - `library` → `micro` (Microfeature Architecture: Example / Interface / Impl / Tests / Testing)
  - `standard` → `lite` (Microfeature lite: Interface / Impl / Tests / Testing)
  - `simple` remains unchanged
- **Lite module now has 4 layers** (was 3):
  - Added Interface layer for dependency inversion
  - New structure: Interface / Implementation / Tests / Testing

### ✨ New Features

- **`flutist check` command**: Validates architecture rules for module dependencies
  - Implementation direct reference detection (with compositionRoots exception)
  - Circular dependency detection
  - Testing/Example layer reference restrictions
  - Clean module layer direction enforcement
- **`ProjectOptions` configuration**:
  - `strictMode` (default: `true`): Enforces architecture rules during `flutist generate`
  - `compositionRoots` (default: `['app']`): Modules allowed to reference Implementation directly
- **Architecture validation in `flutist generate`**:
  - When `strictMode: true`, generation aborts if violations are found
  - When `strictMode: false`, generation proceeds without validation

- **`flutist test` command**: Run tests across all modules in parallel
  - Automatically finds modules with `test/` directories
  - `--module <name>` option to test a specific module
  - Aggregated pass/fail summary with exit code 1 on failure

### 🔧 Refactored

- Removed unused `template.dart` (Template, Attribute, TemplateItem classes)
- Added `ModuleType.fromString()` to replace 3 duplicate `_parseModuleType` methods
- Added `StringCase` utility class for shared case conversions
- Extracted `ProjectParser` from `GenerateCommand` for shared parsing
- Merged `checker/`, `generator/`, `parser/` into unified `engine/` directory
- Reused `GenFileGenerator.parsePackageDart()` across commands

### 🧪 Tests

- Added unit test suite (61 tests):
  - `StringCase` case conversion + round-trip verification
  - `ModuleType.fromString()` validation + old name rejection
  - `ArchitectureChecker` all 5 rules + edge cases
  - `ProjectParser` file I/O + options parsing
  - `GenFileGenerator` package.dart parsing + round-trip verification

### 📦 Migration Guide

Update all references to old module type names:

```dart
// Before (1.x)
Module(name: 'login', type: ModuleType.feature)
Module(name: 'network', type: ModuleType.library)
Module(name: 'models', type: ModuleType.standard)

// After (2.0.0)
Module(name: 'login', type: ModuleType.clean)
Module(name: 'network', type: ModuleType.micro)
Module(name: 'models', type: ModuleType.lite)
```

Update CLI commands:

```bash
# Before
flutist create --options feature

# After
flutist create --options clean
```

## [1.1.3] - 2025-01-02

### 📝 Documentation
- Simplified README.md to core content (removed detailed documentation for future docs site)
- Added Docs badge with book icon linking to DeepWiki documentation
- Updated all documentation links to https://deepwiki.com/seonwooke/flutist
- Updated pubspec.yaml documentation field to point to DeepWiki

## [1.1.2] - 2025-01-02

### 📝 Documentation
- Updated README.md version badge to reflect current version (1.1.1)
- Fixed project structure documentation:
  - Corrected `main.dart` location to `root/lib/main.dart` (was incorrectly shown in `app/lib/main.dart`)
  - Clarified that `app.dart` belongs in `app/lib/app.dart`
- Removed `dart test` section from Development Setup (tests not yet implemented)
- Fixed duplicate `lib/` directory in project structure example

## [1.1.1] - 2025-01-02

### ✨ Added
- **Clean Architecture example repository**:
  - Added link to `flutist_clean_architecture` repository in README.md Examples section
  - Added Real-World Examples section to example/README.md
  - Showcases Clean Architecture implementation using Flutist

### 🔧 Improved
- **`flutist generate` command**:
  - Automatically removes deleted modules from `package.dart` when module files are not found
  - When a module's pubspec.yaml cannot be found (e.g., `home_domain`), extracts base module name (e.g., `home`) and removes it from `package.dart`
  - Ensures `package.dart` stays in sync with actual file system structure
  - Filters `flutist_gen.dart` modules to only include those present in `project.dart`
  - Modules removed from `project.dart` are now also removed from `flutist_gen.dart`

### 🐛 Fixed
- Fixed logging message format in generate command

## [1.1.0] - 2025-01-02

### 🚀 Major Changes
- **Project structure update**: Moved `main.dart` from `app/lib/main.dart` to `lib/main.dart`
  - Root `lib/main.dart` now imports and runs app from `package:app/app.dart`
  - App module is automatically added as a path dependency in root `pubspec.yaml`
  - Enables direct execution with `flutter run` from root directory
  - Removed `flutist run` command - use `flutter run` directly instead

### ✨ Added
- Root `lib/main.dart` generation in `flutist init` command
- Automatic app module dependency management in root `pubspec.yaml`

### 🗑️ Removed
- **BREAKING**: `flutist run` command has been removed
  - Users should use `flutter run` directly from the project root
  - This change simplifies the toolchain and aligns with standard Flutter workflows

### 🔧 Changed
- `flutist init` now creates `lib/main.dart` in root directory instead of `app/lib/main.dart`
- Root `pubspec.yaml` template now includes app module as path dependency
- Run command references removed from documentation and help text

## [1.0.10] - 2025-01-02

### 🐛 Fixed
- **`flutist generate` command**:
  - Fixed empty dependencies section being converted from `dependencies:` to `dependencies: {}`
  - Now preserves original format when dependencies section is empty
  - Empty dependencies sections are formatted as `dependencies:` instead of `dependencies: {}`
  - Files with unchanged dependencies no longer show unnecessary format changes

## [1.0.9] - 2025-01-02

### 🐛 Fixed
- **`flutist create` command**:
  - Fixed incorrect `analysis_options.yaml` include path for layered modules (feature, library, standard)
  - Now uses `path.relative()` to correctly calculate relative path from module to root directory
  - Previously calculated depth based on `moduleRelativePath`, which was incorrect for layered modules
  - Example: `features/book_detail/book_detail_domain` now correctly uses `../../../analysis_options.yaml` instead of `../../analysis_options.yaml`

## [1.0.8] - 2025-01-02

### 🐛 Fixed
- **`flutist init` command**:
  - Fixed version detection using `dart pub global list` command instead of pubspec.yaml lookup
  - `global_packages` directory doesn't contain `pubspec.yaml`, only `pubspec.lock`
  - Now correctly reads installed flutist version from `dart pub global list` output
  - Fixes issue where version detection failed for globally installed packages via `dart pub global activate`

## [1.0.7] - 2025-01-02

### 🐛 Fixed
- **`flutist init` command**:
  - Fixed version detection when running `flutist init` after `dart pub global activate flutist`
  - Prioritized `global_packages` lookup to correctly read installed flutist version
  - Added package name validation to ensure correct `pubspec.yaml` is read
  - Simplified version detection logic by removing unnecessary directory traversal
  - Now correctly adds the installed flutist version to project dependencies instead of fallback version

## [1.0.6] - 2025-01-02

### 🔧 Improved
- **`flutist init` command**:
  - Dynamically reads flutist package version from current package's `pubspec.yaml`
  - Uses pub.dev package instead of local path reference
  - Automatically reflects version updates when `pubspec.yaml` is updated
  - Changed from hardcoded version to dynamic version reading

## [1.0.5] - 2025-01-02

### 🎨 Style
- Applied Dart formatter to example files and codebase
  - Formatted `example/flutist/flutist_gen.dart`
  - Formatted `example/package.dart`
  - Applied consistent code formatting across the project

## [1.0.4] - 2025-01-02

### 🐛 Fixed
- Fixed `flutist run` command creating `root/lib/main.dart` file
  - Added explicit `-t` flag to target `app/lib/main.dart` when running Flutter
  - Automatically detects and removes existing `root/lib/main.dart` if found
  - Prevents Flutter from auto-creating `root/lib/main.dart` file

## [1.0.3] - 2025-01-02

### 🐛 Fixed
- Fixed `flutist run` command creating unnecessary `root/lib/main.dart` file
  - Removed auto-generation logic that created `root/lib/main.dart` when missing
  - Flutter workspace automatically finds `app/lib/main.dart` when running from root directory
  - Updated README.md documentation to reflect correct behavior

## [1.0.2] - 2025-01-02

### ✨ Added
- Example directory for pub.dev with complete project structure demonstration
  - `README.md` with usage instructions and module type explanations
  - `directory_structure.md` with Microfeature Architecture visualization
  - Example `package.dart` and `project.dart` configuration files
  - Example `pubspec.yaml` with workspace configuration
  - Example `flutist_gen.dart` showing generated code structure

### 🔧 Improved
- **`flutist init` command**:
  - Prevent overwriting existing `README.md` files
  - Merge Flutist configuration into existing `pubspec.yaml` instead of overwriting
  - Automatically add `workspace` section if missing
  - Automatically add `app` module to workspace if not exists
  - Automatically add `flutist` dependency with latest version when merging
  - Fix `app.dart` import path in `main.dart` (use relative import instead of package import)
- **README.md**:
  - Add "Core Commands" section highlighting main 4 commands (`init`, `create`, `generate`, `scaffold`)
  - Add "All Commands" table at the top for quick reference
  - Improve command visibility with larger headings and bold text
  - Add `scaffold` example to Quick Start section

### 🐛 Fixed
- Fixed import path in generated `app/lib/main.dart` (changed from `package:app/app.dart` to `app.dart`)
- Fixed dependency getter names in example files (camelCase conversion: `shared_preferences` → `sharedPreferences`, `json_annotation` → `jsonAnnotation`)
- Suppressed warnings in example directory with custom `analysis_options.yaml`

## [1.0.1] - 2025-01-02

### 🐛 Fixed
- Fixed README.md banner image loading issue by using GitHub raw URL instead of relative path

## [1.0.0] - 2025-01-02

### 🎉 Initial Release

Flutist is a Flutter project management framework inspired by Tuist, providing declarative module structure and dependency management.

### ✨ Features

#### Core Commands
- **`flutist init`** - Initialize project with workspace support
- **`flutist create`** - Create modules (simple, feature, library, standard)
- **`flutist generate`** - Sync dependencies with type-safe auto-completion
- **`flutist scaffold`** - Generate code from templates (Tuist-style)
- **`flutist graph`** - Visualize module dependencies (Mermaid, DOT, ASCII)
- **`flutist run`** - Run Flutter app
- **`flutist pub`** - Manage packages

### 🏗️ Module Types
- **Simple** - Single-layer module
- **Feature** - 3-layer (Domain, Data, Presentation)
- **Library** - 5-layer (Example, Interface, Implementation, Testing, Tests)
- **Standard** - 3-layer (Implementation, Tests, Testing)

### 📦 What's Included
- Auto-generated `flutist_gen.dart` for type-safe dependencies
- Built-in feature template (BLoC pattern)
- Comprehensive `analysis_options.yaml` (100+ lint rules)
- Automatic workspace registration
- Smart relative path calculation

### 🐛 Known Issues
- iOS build requires workspace workaround (Flutter limitation)
  - **Solution**: Use Android/Web for development

### 📚 Quick Example
```bash
flutist init
flutist create --path features --name login --options library
flutist generate
flutist graph --open
```

### 🙏 Credits
Inspired by [Tuist](https://tuist.io/)

---

[3.0.0]: https://github.com/seonwooke/flutist/releases/tag/v3.0.0
[2.1.0]: https://github.com/seonwooke/flutist/releases/tag/v2.1.0
[2.0.0]: https://github.com/seonwooke/flutist/releases/tag/v2.0.0
[1.1.3]: https://github.com/seonwooke/flutist/releases/tag/v1.1.3
[1.1.2]: https://github.com/seonwooke/flutist/releases/tag/v1.1.2
[1.1.1]: https://github.com/seonwooke/flutist/releases/tag/v1.1.1
[1.1.0]: https://github.com/seonwooke/flutist/releases/tag/v1.1.0
[1.0.10]: https://github.com/seonwooke/flutist/releases/tag/v1.0.10
[1.0.9]: https://github.com/seonwooke/flutist/releases/tag/v1.0.9
[1.0.8]: https://github.com/seonwooke/flutist/releases/tag/v1.0.8
[1.0.7]: https://github.com/seonwooke/flutist/releases/tag/v1.0.7
[1.0.6]: https://github.com/seonwooke/flutist/releases/tag/v1.0.6
[1.0.5]: https://github.com/seonwooke/flutist/releases/tag/v1.0.5
[1.0.4]: https://github.com/seonwooke/flutist/releases/tag/v1.0.4
[1.0.3]: https://github.com/seonwooke/flutist/releases/tag/v1.0.3
[1.0.2]: https://github.com/seonwooke/flutist/releases/tag/v1.0.2
[1.0.1]: https://github.com/seonwooke/flutist/releases/tag/v1.0.1
[1.0.0]: https://github.com/seonwooke/flutist/releases/tag/v1.0.0
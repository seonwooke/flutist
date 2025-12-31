import 'core.dart';

/// Represents a central package configuration in a Flutist project.
/// This class defines all available dependencies and modules that can be referenced by individual modules.
/// Typically defined in a 'package.dart' file for centralized dependency management.
///
/// Flutist 프로젝트의 중앙 패키지 설정을 나타냅니다.
/// 개별 모듈에서 참조할 수 있는 모든 의존성과 모듈을 정의합니다.
/// 중앙화된 의존성 관리를 위해 일반적으로 'package.dart' 파일에 정의됩니다.
///
/// Example / 예시:
/// ```dart
/// final package = Package(
///   name: 'my_workspace',
///   dependencies: [
///     Dependency(name: 'intl', version: '^0.18.0', isDev: false),
///     Dependency(name: 'dio', version: '^5.0.0', isDev: false),
///   ],
///   devDependencies: [
///     Dependency(name: 'test', version: '^1.24.0', isDev: true),
///     Dependency(name: 'mockito', version: '^5.0.0', isDev: true),
///   ],
///   modules: [
///     Module(name: 'user_domain', ...),
///     Module(name: 'auth_feature', ...),
///   ],
/// );
/// ```
class Package {
  /// The name of the package.
  /// This typically matches the workspace or project name.
  ///
  /// 패키지의 이름.
  /// 일반적으로 워크스페이스 또는 프로젝트 이름과 일치합니다.
  final String name;

  /// List of regular dependencies available for modules to use.
  /// These dependencies will be added to the 'dependencies' section of pubspec.yaml.
  ///
  /// 모듈에서 사용할 수 있는 일반 의존성 목록.
  /// 이 의존성들은 pubspec.yaml의 'dependencies' 섹션에 추가됩니다.
  final List<Dependency> dependencies;

  /// List of all modules defined in this package.
  /// These modules can be referenced as dependencies by other modules.
  ///
  /// 이 패키지에 정의된 모든 모듈 목록.
  /// 이 모듈들은 다른 모듈의 의존성으로 참조될 수 있습니다.
  final List<Module> modules;

  /// Creates a new Package.
  /// 새로운 Package를 생성합니다.
  Package({
    required this.name,
    this.dependencies = const [],
    this.modules = const [],
  });
}

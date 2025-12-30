import 'core.dart';

/// Represents the root configuration of a Flutist project.
/// This is the top-level structure that defines the entire project with its modules and settings.
///
/// Flutist 프로젝트의 루트 설정을 나타냅니다.
/// 모듈과 설정을 포함한 전체 프로젝트를 정의하는 최상위 구조입니다.
///
/// Example / 예시:
/// ```dart
/// final project = Project(
///   name: 'my_app',
///   options: ProjectOptions(
///     useCustomTemplate: true,
///     defaultPaths: {...},
///   ),
///   modules: [
///     Module(
///       name: 'user_domain',
///       dependencies: [...],
///       devDependencies: [...],
///       modules: [],
///     ),
///     Module(
///       name: 'app',
///       dependencies: [...],
///       devDependencies: [...],
///       modules: [],
///     ),
///   ],
/// );
/// ```
class Project {
  /// The name of the project.
  /// This typically matches the root project directory name.
  ///
  /// 프로젝트의 이름.
  /// 일반적으로 루트 프로젝트 디렉토리 이름과 일치합니다.
  final String name;

  /// Configuration options for the project.
  /// Controls project behavior and module generation settings.
  /// Defaults to ProjectOption() if not specified.
  ///
  /// 프로젝트의 설정 옵션.
  /// 프로젝트 동작과 모듈 생성 설정을 제어합니다.
  /// 지정하지 않으면 기본 ProjectOption()이 사용됩니다.
  final ProjectOptions options;

  /// List of modules in this project.
  /// Each module represents a distinct package or feature in the workspace.
  ///
  /// 이 프로젝트의 모듈 목록.
  /// 각 모듈은 워크스페이스 내의 개별 패키지 또는 기능을 나타냅니다.
  final List<Module> modules;

  /// Creates a new Project.
  /// 새로운 Project를 생성합니다.
  Project({
    required this.name,
    this.options = const ProjectOptions(),
    this.modules = const [],
  });
}

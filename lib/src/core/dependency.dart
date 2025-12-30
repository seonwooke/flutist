/// Represents a dependency in a Flutist project.
/// This can be either a pub.dev package or an internal module.
///
/// Flutist 프로젝트의 의존성을 나타냅니다.
/// pub.dev 패키지 또는 내부 모듈이 될 수 있습니다.
class Dependency {
  /// The name of the dependency.
  /// 의존성의 이름.
  final String name;

  /// The version constraint (e.g., '^1.0.0', 'any').
  /// 버전 제약 조건 (예: '^1.0.0', 'any').
  final String version;

  /// Whether this is a dev dependency (appears in dev_dependencies section).
  /// dev dependency 여부 (dev_dependencies 섹션에 포함됨).
  final bool isDev;

  /// Creates a new Dependency.
  /// 새로운 Dependency를 생성합니다.
  Dependency({
    required this.name,
    required this.version,
    this.isDev = false,
  });
}

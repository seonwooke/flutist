/// Configuration options for a Flutist project.
/// Controls project behavior and module generation settings.
///
/// Flutist 프로젝트의 설정 옵션입니다.
/// 프로젝트 동작과 모듈 생성 설정을 제어합니다.
///
/// Example / 예시:
/// ```dart
/// ProjectOption(
///   useCustomTemplate: true,
///   strictMode: false,
///   moduleTemplates: {
///     ModuleType.feature: 'templates/feature',
///     ModuleType.simple: 'templates/simple',
///   },
/// )
/// ```
class ProjectOptions {
  /// Whether to use custom templates for module generation.
  /// If false, uses Flutist's default templates.
  ///
  /// 모듈 생성 시 커스텀 템플릿 사용 여부.
  /// false인 경우 Flutist의 기본 템플릿을 사용합니다.
  final bool useCustomTemplate;

  /// Whether to enable strict mode for dependency validation.
  /// In strict mode, circular dependencies and invalid references are rejected.
  /// (Not implemented yet)
  ///
  /// 의존성 검증을 위한 엄격 모드 활성화 여부.
  /// 엄격 모드에서는 순환 의존성과 잘못된 참조가 거부됩니다.
  /// (아직 구현되지 않음)
  // final bool strictMode;

  /// Creates a new ProjectOption.
  /// 새로운 ProjectOption을 생성합니다.
  const ProjectOptions({
    this.useCustomTemplate = false,
  });
}

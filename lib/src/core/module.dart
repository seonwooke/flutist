import 'core.dart';

/// Defines the structural type of a module in a Flutist project.
/// Each type has a predefined layer structure.
///
/// Flutist 프로젝트에서 모듈의 구조 타입을 정의합니다.
/// 각 타입은 미리 정의된 레이어 구조를 가집니다.
enum ModuleType {
  /// Feature module with Domain, Data, Presentation 3-layer structure.
  /// Used for implementing features following Clean Architecture principles.
  ///
  /// Domain, Data, Presentation 3-레이어 구조의 기능 모듈.
  /// Clean Architecture 원칙을 따르는 기능 구현에 사용됩니다.
  feature,

  /// Library module with Example, Implementation, Interface, Tests, Testing 5-layer structure.
  /// Used for creating reusable packages with comprehensive structure.
  ///
  /// Example, Implementation, Interface, Tests, Testing 5-레이어 구조의 라이브러리 모듈.
  /// 포괄적인 구조를 가진 재사용 가능한 패키지 생성에 사용됩니다.
  library,

  /// Standard module with Implementation, Tests, Testing 3-layer structure.
  /// Used for typical domain or data modules.
  ///
  /// Implementation, Tests, Testing 3-레이어 구조의 표준 모듈.
  /// 일반적인 도메인 또는 데이터 모듈에 사용됩니다.
  standard,

  /// Simple module with only lib folder.
  /// Used for single-purpose modules or app modules.
  ///
  /// lib 폴더만 있는 단순 모듈.
  /// 단일 목적 모듈이나 앱 모듈에 사용됩니다.
  simple,
}

/// Represents a module in a Flutist project.
/// A module can contain dependencies, dev dependencies, and sub-modules.
///
/// Flutist 프로젝트의 모듈을 나타냅니다.
/// 모듈은 의존성, 개발 의존성, 그리고 하위 모듈을 포함할 수 있습니다.
class Module {
  /// The name of the module.
  /// 모듈의 이름.
  final String name;

  /// The type of the module.
  /// 모듈의 유형.
  final ModuleType type;

  /// Regular dependencies that will be added to the 'dependencies' section.
  /// 'dependencies' 섹션에 추가될 일반 의존성 목록.
  final List<Dependency> dependencies;

  /// Development dependencies that will be added to the 'dev_dependencies' section.
  /// 'dev_dependencies' 섹션에 추가될 개발 의존성 목록.
  final List<Dependency> devDependencies;

  /// Sub-modules or module dependencies within this module.
  /// 이 모듈 내의 하위 모듈 또는 모듈 의존성 목록.
  final List<Module> modules;

  /// Creates a new Module.
  /// 새로운 Module을 생성합니다.
  Module({
    required this.name,
    this.type = ModuleType.library,
    this.dependencies = const [],
    this.devDependencies = const [],
    this.modules = const [],
  });
}

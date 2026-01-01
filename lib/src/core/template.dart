// lib/src/core/template.dart

/// Represents a scaffold template.
/// 스캐폴드 템플릿을 나타냅니다.
class Template {
  /// Description of what this template does.
  /// 이 템플릿이 무엇을 하는지에 대한 설명.
  final String description;

  /// List of required and optional attributes.
  /// 필수 및 선택적 속성 목록.
  final List<Attribute> attributes;

  /// List of files and directories to generate.
  /// 생성할 파일 및 디렉토리 목록.
  final List<TemplateItem> items;

  const Template({
    required this.description,
    required this.attributes,
    required this.items,
  });
}

/// Represents an attribute (variable) in a template.
/// 템플릿의 속성(변수)을 나타냅니다.
class Attribute {
  final String name;
  final bool isRequired;
  final String? defaultValue;

  const Attribute({
    required this.name,
    this.isRequired = false,
    this.defaultValue,
  });

  /// Creates a required attribute.
  /// 필수 속성을 생성합니다.
  static Attribute required(String name) {
    return Attribute(name: name, isRequired: true);
  }

  /// Creates an optional attribute with a default value.
  /// 기본값이 있는 선택적 속성을 생성합니다.
  static Attribute optional(String name, {String? defaultValue}) {
    return Attribute(
      name: name,
      isRequired: false,
      defaultValue: defaultValue,
    );
  }
}

/// Base class for template items.
/// 템플릿 항목의 기본 클래스.
abstract class TemplateItem {
  const TemplateItem();
}

/// Represents a file to be generated from a template.
/// 템플릿에서 생성될 파일을 나타냅니다.
class TemplateFile extends TemplateItem {
  /// Output path with variable placeholders (e.g., "lib/{{name}}/{{name}}_bloc.dart")
  /// 변수 플레이스홀더가 포함된 출력 경로.
  final String path;

  /// Template file path (e.g., "bloc.dart.template")
  /// 템플릿 파일 경로.
  final String templatePath;

  const TemplateFile({
    required this.path,
    required this.templatePath,
  });
}

/// Represents a directory to be copied.
/// 복사될 디렉토리를 나타냅니다.
class TemplateDirectory extends TemplateItem {
  /// Output directory path with variable placeholders
  /// 변수 플레이스홀더가 포함된 출력 디렉토리 경로.
  final String path;

  /// Source directory path in the template
  /// 템플릿의 소스 디렉토리 경로.
  final String sourcePath;

  const TemplateDirectory({
    required this.path,
    required this.sourcePath,
  });
}

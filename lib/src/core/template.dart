/// Represents a scaffold template.
class Template {
  /// Template description.
  final String description;

  /// Required and optional attributes.
  final List<Attribute> attributes;

  /// Files and directories to generate.
  final List<TemplateItem> items;

  const Template({
    required this.description,
    required this.attributes,
    required this.items,
  });
}

/// Represents an attribute (variable) in a template.
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
  static Attribute required(String name) {
    return Attribute(name: name, isRequired: true);
  }

  /// Creates an optional attribute with a default value.
  static Attribute optional(String name, {String? defaultValue}) {
    return Attribute(
      name: name,
      isRequired: false,
      defaultValue: defaultValue,
    );
  }
}

/// Base class for template items.
abstract class TemplateItem {
  const TemplateItem();
}

/// Represents a file to be generated from a template.
class TemplateFile extends TemplateItem {
  /// Output path with variable placeholders.
  final String path;

  /// Template file path.
  final String templatePath;

  const TemplateFile({
    required this.path,
    required this.templatePath,
  });
}

/// Represents a directory to be copied.
class TemplateDirectory extends TemplateItem {
  /// Output directory path with variable placeholders.
  final String path;

  /// Source directory path in the template.
  final String sourcePath;

  const TemplateDirectory({
    required this.path,
    required this.sourcePath,
  });
}

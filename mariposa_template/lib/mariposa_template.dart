import 'package:html_builder/html_builder.dart';

/// An annotation that instructs `package:mariposa_template_generator` on how to generate code for a static HTML template.
class Template {
  /// The name of the HTML tag to generate.
  ///
  /// Defaults to `div`.
  final String tagName;

  /// The template to be generated, as a [String].
  final String template;

  /// A relative URI pointing to a file containing the [template].
  final String templateUrl;

  /// Whether to create a `ContextAwareWidget`.
  ///
  /// Defaults to `false`.
  final bool contextAware;

  /// Functions and types that can be used as custom HTML elements.
  ///
  /// All attributes are expected to be supported as named parameters.
  ///
  /// If the HTML element is given children, these will be passed to a
  /// named parameter, `Iterable<Node> c`.
  final List directives;

  const Template(
      {this.template,
      this.templateUrl,
      this.contextAware: false,
      this.tagName: 'div',
      this.directives: const []});
}

Node ngIf(bool condition, Iterable<Node> children, {String tagName: 'div'}) =>
    condition != true ? null : h(tagName, {}, children ?? []);

Node ngFor<T>(Iterable<T> items, Node Function(T) f, {String tagName: 'div'}) =>
    h(tagName, {}, items?.map(f) ?? []);

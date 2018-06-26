import 'dart:async';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

class TemplateReader {
  final ConstantReader constantReader;
  List<DirectiveReader> _directives;
  String _template;

  TemplateReader(this.constantReader);

  bool get isContextAware =>
      constantReader.peek('contextAware')?.boolValue ?? false;

  String get cachedTemplate =>
      _template ??= throw new StateError('The template has not yet been read.');

  String get tagName => constantReader.peek('tagName')?.stringValue ?? 'div';

  List<DirectiveReader> get directives {
    if (_directives != null) return _directives;
    var d = constantReader.peek('directives')?.listValue ?? [];
    return _directives = new List<DirectiveReader>.unmodifiable(
        d.map((o) => new DirectiveReader(new ConstantReader(o))));
  }

  Future<String> readTemplate(AssetId assetId, AssetReader reader) async {
    if (_template != null) return _template;
    var template = constantReader.peek('template')?.stringValue;
    var templateUrl = constantReader.peek('templateUrl')?.stringValue;

    if (template == null && templateUrl == null)
      throw 'The @Template() annotation has neither a `template` or `templateUrl` set.';

    if (template != null) return _template = template;

    var id = new AssetId(
        assetId.package, p.relative(templateUrl, from: assetId.path));
    return _template = await reader.readAsString(id);
  }
}

class DirectiveReader {
  final ConstantReader constantReader;

  DirectiveReader(this.constantReader);

  bool get isClass => constantReader.isType;

  bool get isFunction => const TypeChecker.fromRuntime(Function)
      .isAssignableFromType(constantReader.objectValue.type);

  String get name {
    if (isClass) {
      return constantReader.typeValue.name;
    }

    throw new ArgumentError();
  }
}

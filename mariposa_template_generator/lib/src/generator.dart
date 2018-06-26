import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:angular_ast/angular_ast.dart';
import 'package:build/build.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:code_builder/code_builder.dart';
import 'package:mariposa/mariposa.dart';
import 'package:mariposa_template/mariposa_template.dart';
import 'package:source_gen/source_gen.dart';
import 'package:string_scanner/string_scanner.dart';
import 'compiler.dart';
import 'template_reader.dart';

const TypeChecker widgetTypeChecker = const TypeChecker.fromRuntime(Widget);
const TypeChecker contextAwareWidgetTypeChecker =
    const TypeChecker.fromRuntime(ContextAwareWidget);

class MariposaTemplateGenerator extends GeneratorForAnnotation<Template> {
  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    var reader = new TemplateReader(annotation);
    var handler = new RecoveringExceptionHandler();
    var parsed = parse(
      await reader.readTemplate(buildStep.inputId, buildStep),
      sourceUrl: buildStep.inputId.toString(),
      toolFriendlyAst: true,
      exceptionHandler: handler,
    );

    if (handler.exceptions.isNotEmpty) {
      for (var error in handler.exceptions) {
        var msg = new StringBuffer()
          ..write(error.errorCode.errorSeverity.displayName)
          ..write(': ')
          ..writeln(error.errorCode.message);

        if (error.errorCode.correction != null)
          msg.writeln(error.errorCode.correction);

        var scanner = new SpanScanner(reader.cachedTemplate,
            sourceUrl: buildStep.inputId.uri)
          ..position = error.offset;

        msg
          ..writeln()
          ..writeln('The following text is where the error occurred:')
          ..writeln(scanner.emptySpan.start.toolString)
          ..writeln(scanner.emptySpan.highlight(color: true));

        log.severe(msg);
      }

      throw 'Parsing of Angular template completed with ' +
          '${handler.exceptions.length} error(s).';
    }

    TemplateContext ctx;

    if (element is ClassElement) {
      /*if (!widgetTypeChecker.isAssignableFromType(element.type)) {
        throw '@Template() cannot be attached to class ${element.name},' +
            ' because it does not extend Widget.';
      }*/

      /*var contextAware =
          contextAwareWidgetTypeChecker.isAssignableFromType(element.type);*/
      ctx = new TemplateContext(true, reader, element.name, parsed, null);
    } else if (element is FunctionElement) {
      if (element.name == null)
        throw '@Template() cannot be applied to anonymous functions.';

      if (!element.isExternal)
        throw '@Template() expects the function ${element
            .name} to labeled as `external`.';

      if (element.name == '_')
        throw '@Template() cannot be applied to a function with the name "_".';

      if (!element.name.startsWith('_')) {
        throw '@Template() can only be applied to functions with names that start with "_".' +
            ' However, ${element.name} does not fit this criteria.' +
            ' Please rename it to "_${element.name}".';
      }

      ctx = new TemplateContext(
          false, reader, element.name.substring(1), parsed, element);
    } else {
      throw '@Template() can only be applied to functions and classes.';
    }

    var lib = compile(ctx);
    return lib.accept(new DartEmitter()).toString();
  }
}

import 'package:analyzer/analyzer.dart' hide Block, Expression;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:angular_ast/angular_ast.dart';
import 'package:code_builder/code_builder.dart';
import 'package:recase/recase.dart';
import 'template_reader.dart';

class TemplateContext {
  final bool isClass;
  final TemplateReader template;
  final String name;
  final List<TemplateAst> parsed;
  final FunctionElement functionElement;

  TemplateContext(this.isClass, this.template, this.name, this.parsed,
      this.functionElement);
}

Library compile(TemplateContext ctx) {
  return new Library((lib) {
    if (ctx.isClass)
      lib.body.add(compileClass(ctx));
    else
      lib.body.add(compileFunction(ctx, lib.body.add));
  });
}

Class compileClass(TemplateContext ctx) {
  return new Class((clazz) {
    clazz
      ..name = '_' + new ReCase(ctx.name).pascalCase + 'Template'
      ..abstract = true
      ..extend =
          refer(ctx.template.isContextAware ? 'ContextAwareWidget' : 'Widget')
      ..methods.add(new Method((method) {
        if (ctx.template.isContextAware) {
          method.requiredParameters.add(new Parameter((b) => b
            ..name = 'context'
            ..type = refer('RenderContext')));
        }

        method
          ..name = ctx.template.isContextAware ? 'contextAwareRender' : 'render'
          ..annotations.add(refer('override'))
          ..body = compileRenderMethod(method, ctx, clazz.methods.add);
      }));
  });
}

Method compileFunction(TemplateContext ctx, void Function(Method) addMethod) {
  return new Method((method) {
    for (var parameter in ctx.functionElement.parameters) {
      var p = new Parameter((b) {
        b
          ..name = parameter.name
          ..named = parameter.parameterKind == ParameterKind.NAMED
          ..type = compileType(parameter.type);

        if (parameter.defaultValueCode != null)
          b.defaultTo = new Code(parameter.defaultValueCode);
      });

      if (parameter.parameterKind.isOptional) {
        method.optionalParameters.add(p);
      } else {
        method.requiredParameters.add(p);
      }
    }

    method
      ..name = ctx.name
      ..returns = compileType(ctx.functionElement.returnType)
      ..docs.addAll(ctx.functionElement.documentationComment?.split('\n') ?? [])
      ..body = compileRenderMethod(method, ctx, addMethod);
  });
}

Reference compileType(DartType type) {
  if (type is InterfaceType) {
    if (type.typeArguments.isEmpty) return refer(type.name);
    return new TypeReference((b) => b
      ..symbol = type.name
      ..types.addAll(type.typeArguments.map(compileType)));
  } else {
    return refer(type.name);
  }
}

Code compileRenderMethod(MethodBuilder method, TemplateContext ctx,
    void Function(Method) addMethod) {
  return new Block((block) {
    var builder = refer('builder');

    // var builder = new NodeBuilder('...');
    block.statements.add(
      refer('NodeBuilder')
          .newInstance([literalString(ctx.template.tagName)])
          .assignVar('builder')
          .statement,
    );

    // Each template should just create an anonymous function and call it.
    for (int i = 0; i < ctx.parsed.length; i++) {
      var name = '_' + new ReCase(ctx.name).camelCase + 'Child$i';

      addMethod(new Method((method) {
        method
          ..name = name
          ..returns = refer('Node')
          ..body = new Block((block) {
            block.statements
                .add(compileTemplateAst(ctx.parsed[i], ctx).returned.statement);
          });
      }));

      // Call addChild(...);
      block.addExpression(
        builder.assign(builder.property('addChild').call([
          refer(name).call([]),
        ])),
      );
    }

    // return builder.build();
    block.addExpression(builder.property('build').call([]).returned);
  });
}

Expression compileTemplateAst(TemplateAst ast, TemplateContext ctx) {
  if (ast is TextAst) {
    // TODO: Expressions, etc.
    return refer('text').call([literalString(ast.value.trim().isEmpty ? '' : ast.value.trim())]);
  }

  if (ast is ParsedElementAst) {
    // TODO: Call functions instead
    var attrs = {};

    for (var attr in ast.attributes) {
      attrs[attr.name] = attr.value;
    }

    return refer('h').call([
      literalString(ast.name),
      literalMap(attrs),
      literalList(ast.childNodes.map((node) => compileTemplateAst(node, ctx))),
    ]);
  }


  return refer('h').call([
    literalString(ast.runtimeType.toString()),
    literalMap({}),
    literalList(ast.childNodes.map((node) => compileTemplateAst(node, ctx))),
  ]);
}

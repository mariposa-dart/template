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
      lib.body.add(compileFunction(ctx));
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
          ..body = compileRenderMethod(ctx, clazz.methods.add);
      }));
  });
}

Method compileFunction(TemplateContext ctx) {
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
      ..body = new Block((block) {
        block.statements.addAll(
          compileRenderMethod(
                  ctx, (method) => block.statements.add(method.closure.code))
              .statements,
        );
      });
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

Block compileRenderMethod(
    TemplateContext ctx, void Function(Method) addMethod) {
  return new Block((block) {
    var builder = refer('builder');

    // Add String _toString(x) => x.toString();
    addMethod(new Method((b) {
      b
        ..name = '_toString'
        ..returns = refer('String')
        ..body = refer('x').property('toString').call([]).returned.statement
        ..requiredParameters.add(new Parameter((b) => b..name = 'x'))
        ..docs.add('// ignore: unused_element');
    }));

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
    return refer('text')
        .call([literalString(ast.value.replaceAll('\n', '\\n'))]);
  }

  if (ast is ParsedInterpolationAst) {
    return refer('text').call([
      refer('_toString').call([
        new CodeExpression(new Code(ast.value.replaceAll('\n', '\\n'))),
      ])
    ]);
  }

  if (ast is ParsedElementAst) {
    var attrs = <String, Expression>{};
    var children = new List<Expression>.from(
        ast.childNodes.map((node) => compileTemplateAst(node, ctx)));

    for (var attr in ast.attributes) {
      compileAttribute(attr, attrs, ctx);
    }

    var directive = ctx.template.findDirective(ast.name);

    if (directive == null) {
      return refer('h').call([
        literalString(ast.name),
        literalMap(attrs),
        literalList(children),
      ]);
    } else if (directive.isClass) {
      return refer(directive.name)
          .newInstance([], attrs..['c'] = literalList(children));
    } else {
      return refer(directive.name)
          .call([], attrs..['c'] = literalList(children));
    }
  }

  if (ast is ParsedStarAst) {
    return refer(ast.name).call([
      new CodeExpression(new Code(ast.value)),
      literalList(ast.childNodes.map((node) => compileTemplateAst(node, ctx))),
    ]);
  }

  if (ast is EmbeddedTemplateAst) {
    return compileEmbeddedTemplateAst(ast, ctx);
  }

  throw new UnsupportedError(
      'Cannot yet compile ${ast.runtimeType}:\n${ast.sourceSpan.highlight(
          color: true)}');
}

Expression compileEmbeddedTemplateAst(
    EmbeddedTemplateAst ast, TemplateContext ctx) {
  if (ast.attributes.isEmpty) {
    if (ast.isSynthetic) {
      return compileSyntheticTemplate(ast as SyntheticTemplateAst, ctx);
    }

    throw new UnsupportedError(
        'Cannot yet compile embedded template without attributes:\n${ast
            .sourceSpan.highlight(
            color: true)}');
  }

  var attr = ast.attributes.first;

  if (ast.letBindings.isEmpty) {
    throw new StateError(
        '*${attr.name} without any "let" bindings:\n${attr.sourceSpan.highlight(
            color: true)}');
  }

  // We want to return a call to ngFor(items, (item) => ...);

  var binding = ast.letBindings.first;
  var closure = new Method((b) {
    // Just return a div with the children...
    b
      ..requiredParameters.add(new Parameter((b) => b..name = binding.name))
      ..body = refer('div')
          .call([], {
            'c': literalList(
                ast.childNodes.map((child) => compileTemplateAst(child, ctx)))
          })
          .returned
          .statement;
  });

  return refer(attr.name).call([
    new CodeExpression(new Code(binding.value)),
    closure.closure,
  ]);
}

Expression compileSyntheticTemplate(
    SyntheticTemplateAst ast, TemplateContext ctx) {
  return compileTemplateAst(ast.origin, ctx);
}

void compileAttribute(
    AttributeAst attr, Map<String, Expression> attrs, TemplateContext ctx) {
  if (attr is ParsedAttributeAst) {
    // Boolean attribute
    if (attr.value == null) {
      attrs[attr.name] = literalTrue;
    } else if (attr.value != null) {
      attrs[attr.name] = literalString(attr.value);
    } else if (attr.mustaches.isNotEmpty) {
      var parts = attr.mustaches.map<Expression>((ast) {
        return new CodeExpression(new Code(ast.value));
      });

      if (parts.length == 1) {
        attrs[attr.name] = parts.first;
      } else {
        attrs[attr.name] = literalList(parts);
      }
    } else {
      throw new UnsupportedError(
          'Cannot compile attribute:\n${attr.sourceSpan.highlight(
              color: true)}');
    }
  } else {
    attrs[attr.name] = literalString(attr.value);
  }
}

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'generator.dart';

Builder mariposaTemplateBuilder(_) =>
    new PartBuilder([new MariposaTemplateGenerator()],
        generatedExtension: '.mariposa_template.g.dart');

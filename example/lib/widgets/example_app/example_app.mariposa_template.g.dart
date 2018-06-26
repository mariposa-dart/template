// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example_app.dart';

// **************************************************************************
// MariposaTemplateGenerator
// **************************************************************************

abstract class _ExampleAppTemplate extends Widget {
  Node _exampleAppChild0() {
    return text('');
  }

  Node _exampleAppChild1() {
    return h('div', {}, [
      text('Hello, `package:mariposa_template!`'),
      h('br', {}, []),
      text(''),
      h('githubLink', {'target': '_self'}, []),
      text('')
    ]);
  }

  Node _exampleAppChild2() {
    return text('');
  }

  @override
  render() {
    var builder = new NodeBuilder('div');
    builder = builder.addChild(_exampleAppChild0());
    builder = builder.addChild(_exampleAppChild1());
    builder = builder.addChild(_exampleAppChild2());
    return builder.build();
  }
}

Node _githubLinkChild0() {
  return text('');
}

Node _githubLinkChild1() {
  return h('a', {'href': 'https://github.com'}, [text('Go to Github')]);
}

Node _githubLinkChild2() {
  return text('');
}

/// Look, Mom! It's a documentation comment!
Node githubLink({String target: '_blank'}) {
  var builder = new NodeBuilder('div');
  builder = builder.addChild(_githubLinkChild0());
  builder = builder.addChild(_githubLinkChild1());
  builder = builder.addChild(_githubLinkChild2());
  return builder.build();
}

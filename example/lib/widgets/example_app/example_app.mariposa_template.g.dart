// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example_app.dart';

// **************************************************************************
// MariposaTemplateGenerator
// **************************************************************************

abstract class _ExampleAppTemplate extends Widget {
  // ignore: unused_element
  String _toString(x) {
    return x.toString();
  }

  Node _exampleAppChild0() {
    return text('  ');
  }

  Node _exampleAppChild1() {
    return h('div', {}, [
      text('\n    Hello, `package:mariposa_template!`\n    '),
      h('br', {}, []),
      text('\n    '),
      h('githubLink', {'target': '_self'}, []),
      text('\n    '),
      h('br', {}, []),
      text('\n    It\'s now '),
      text(_toString(new DateTime.now())),
      text('.\n    \n    '),
      ngFor(null, (item) {
        return div(c: [
          h('ul', {}, [text('\n      '), ngIf(true, []), text('\n    ')])
        ]);
      }),
      text('\n    \n    '),
      h('button', {}, []),
      text('\n    '),
      h('button', {}, []),
      text('\n  ')
    ]);
  }

  Node _exampleAppChild2() {
    return text('\n  ');
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

/// Look, Mom! It's a documentation comment!
Node githubLink({String target: '_blank'}) {
  // ignore: unused_element
  _toString(x) {
    return x.toString();
  }

  _githubLinkChild0() {
    return text('  ');
  }

  _githubLinkChild1() {
    return h(
        'a', {'href': 'https://github.com'}, [text('\n    Go to Github\n  ')]);
  }

  _githubLinkChild2() {
    return text('\n  ');
  }

  var builder = new NodeBuilder('div');
  builder = builder.addChild(_githubLinkChild0());
  builder = builder.addChild(_githubLinkChild1());
  builder = builder.addChild(_githubLinkChild2());
  return builder.build();
}

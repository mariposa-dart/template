import 'package:html_builder/elements.dart';
import 'package:mariposa/mariposa.dart';
import 'package:mariposa_template/mariposa_template.dart';

part 'example_app.mariposa_template.g.dart';

@Template(
  directives: const [githubLink],
  template: '''
  <div>
    Hello, `package:mariposa_template!`
    <br>
    <githubLink target="_self"></githubLink>
    <br>
    It's now {{new DateTime.now()}}.
    
    <ul *ngFor="let item of [1, 2, 3]">
      <div *ngIf="true"></div>
    </ul>
    
    <button (click)="justBanana()"></button>
    <button [(click)]="bananaInABox()"></button>
  </div>
  ''',
)
class ExampleApp extends _ExampleAppTemplate {}

@Template(template: '''
  <a href="https://github.com" [target]="target">
    Go to Github
  </a>
  ''')
/// Look, Mom! It's a documentation comment!
// ignore: unused_element
external Node _githubLink({String target: '_blank'});

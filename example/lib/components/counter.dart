import 'package:jaspr/jaspr.dart';
import 'package:live_cells_core/live_cells_core.dart';
import 'package:live_cells_jaspr/live_cells_jaspr.dart';

import '../constants/theme.dart';

class Counter extends CellComponent {
  const Counter({super.key});

  @override
  Component build(BuildContext context) {
    final count = MutableCell(0);

    return div([
      div(classes: 'counter', [
        button(
          onClick: () => count.value--,
          [text('-')],
        ),
        span([text('${count()}')]),
        button(
          onClick: () => count.value++,
          [text('+')],
        ),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.counter', [
      css('&').styles(
        display: Display.flex,
        padding: Padding.symmetric(vertical: 10.px),
        border: Border.symmetric(vertical: BorderSide.solid(color: primaryColor, width: 2.px)),
        alignItems: AlignItems.center,
      ),
      css('button', [
        css('&').styles(
          display: Display.flex,
          width: 2.em,
          height: 2.em, 
          border: Border.unset, 
          radius: BorderRadius.all(Radius.circular(2.em)),
          cursor: Cursor.pointer,
          justifyContent: JustifyContent.center, 
          alignItems: AlignItems.center,
          fontSize: 2.rem,
          backgroundColor: Colors.transparent,
        ),
        css('&:hover').styles(
          backgroundColor: const Color('#0001'),
        ),
      ]),
      css('span').styles(
        minWidth: 2.5.em,
        padding: Padding.symmetric(horizontal: 2.rem),
        boxSizing: BoxSizing.borderBox, 
        color: primaryColor, 
        textAlign: TextAlign.center,
        fontSize: 4.rem,
      ),
    ]),
  ];
}

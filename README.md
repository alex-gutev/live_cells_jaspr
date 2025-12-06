This package provides functionality for using the [Live Cells](https://livecell.gutev.dev/) library 
in [Jaspr](https://jaspr.site/) projects.

## Features

This library provides `CellComponent`, which is a Jaspr Component that is rebuilt whenever the
values of the cells referenced within its `build` method change. The API of `CellComponent` is
identical to [`CellWidget`](https://pub.dev/documentation/live_cells/latest/live_cells/CellWidget-class.html).

```dart
class Counter extends CellComponent {
  final MutableCell<int> count;
  
  const Counter({
    super.key,
    required this.count
  });
  
  @override
  Component build(BuildContext context) {
    return div([
      div([
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
}
```

Like [`CellWidget`](https://pub.dev/documentation/live_cells/latest/live_cells/CellWidget-class.html),
for Flutter projects, cells and watch functions can be defined directly in the `build` method:

```dart
class Counter extends CellComponent {
  const Counter({
    super.key,
  });
  
  @override
  Component build(BuildContext context) {
    final count = MutableCell<int>(0);

    ValueCell.watch(() {
      print('Count = ${count()}');
    });

    return div([
      div([
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
}
```

As with [`CellWidget`](https://pub.dev/documentation/live_cells/latest/live_cells/CellWidget-class.html),
cell and watch functions defined within the `build` method, should not be defined conditionally
or in loops.

The `CellComponent.builder` constructor allows you to create a `CellComponent` without subclassing:

```dart
CellComponent.builder((context) {
  final count = MutableCell<int>(0);
  
  ValueCell.watch(() {
    print('Count = ${count()}');
  });
  
  return div([
    div([
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
});
```

## Getting started

To use this library you'll have to add `live_cells_jaspr` and 
[`live_cells_core`](https://pub.dev/packages/live_cells_core) to your project dependencies:

```shell
dart pub add live_cells_core
dart pub add live_cells_jaspr
```

## Additional information

If you discover any issues or have any feature requests, please open an issue on the package's Github
repository.

If you haven't used Live Cells before, head over to the
[documentation](https://alex-gutev.github.io/live_cells/docs/intro) for an introduction and tutorial.

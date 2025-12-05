import 'package:jaspr/browser.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:live_cells_core/live_cells_core.dart';
import 'package:live_cells_core/live_cells_internals.dart';
import 'package:live_cells_jaspr/live_cells_jaspr.dart';
import 'package:mockito/mockito.dart';

/// Mock class interface for recording whether a listener was called
abstract class SimpleListener {
  /// Method added as listener function
  void call();
}

/// Mock class implementing [SimpleListener]
///
/// Usage:
///
///   - Add instance as a listener of a cell
///   - verify(instance())
class MockSimpleListener extends Mock implements SimpleListener {}

/// Track calls to [init] and [dispose] of a [ManagedCellState]
abstract class CellStateTracker {
  void init();
  void dispose();
}

class MockCellStateTracker extends Mock implements CellStateTracker {
  @override
  void init();
  @override
  void dispose();
}

/// A state which calls [init] and [dispose] on [tracker].
///
/// This is used to check that the lifecycle methods of the cell state are
/// being called.
class ManagedCellState extends CellState {
  final CellStateTracker tracker;

  ManagedCellState({
    required super.cell,
    required super.key,
    required this.tracker
  });

  @override
  void init() {
    super.init();
    tracker.init();
  }

  @override
  void dispose() {
    tracker.dispose();
    super.dispose();
  }
}

/// A [StatefulCell] with a constant value for testing cell lifecycle.
///
/// This cell's state calls [CellStateTracker.init] and [CellStateTracker.dispose] on a
/// [CellStateTracker] when the corresponding [CellState] methods are called.
class TestManagedCell<T> extends StatefulCell<T> {
  final CellStateTracker _tracker;

  @override
  final T value;

  TestManagedCell(this._tracker, this.value);

  @override
  CellState<StatefulCell> createState() => ManagedCellState(
      cell: this,
      key: key,
      tracker: _tracker
  );
}

/// Tests CellComponent subclass observing one cell
class CellComponentTest1 extends CellComponent {
  final ValueCell<int> count;

  const CellComponentTest1({
    super.key,
    required this.count
  });

  @override
  Component build(BuildContext context) {
    return text('${count()}');
  }
}

/// Tests CellComponent subclass observing two cells
class CellComponentTest2 extends CellComponent {
  final ValueCell<num> a;
  final ValueCell<num> b;
  final ValueCell<num> sum;

  const CellComponentTest2({
    super.key,
    required this.a,
    required this.b,
    required this.sum
  });

  @override
  Component build(BuildContext context) {
    return text('${a()} + ${b()} = ${sum()}');
  }
}

/// Tests CellComponent subclass with cells defined in build method
class CellComponentTest5 extends CellComponent {
  const CellComponentTest5({super.key});

  @override
  Component build(BuildContext context) {
    final c1 = MutableCell(0);
    final c2 = MutableCell(10);

    return div([
        button(
            onClick: () => c1.value++,
            [text('${c1()}')]
        ),
        button(
            onClick: () => c2.value++,
            [text('${c2()}')]
        )
    ]);
  }
}

/// Tests that cells defined in build method are persisted across builds.
class CellComponentTest6 extends CellComponent {
  const CellComponentTest6({super.key});

  @override
  Component build(BuildContext context) {
    final c1 = MutableCell(0);

    return div([
        button(
            onClick: () => c1.value++,
            [text('${c1()}')]
        ),

        // This component tree is rebuilt whenever the value of c1 changes
        _CellComponentTest6()
    ]);
  }
}

class _CellComponentTest6 extends CellComponent {
  @override
  Component build(BuildContext context) {
    final c2 = MutableCell(10);

    return button(
        onClick: () => c2.value++,
        [text('${c2()}')]
    );
  }
}


/// Tests that the component stops observing cells when it is unmounted
class CellComponentTest8 extends CellComponent {
  final ValueCell<int> a;

  /// Controls the building of the component
  ///
  /// If 0, the component that observes [a] is removed from the tree.
  /// A non-zero value triggers a rebuild of the component
  final ValueCell<int> counter;

  const CellComponentTest8({
    super.key,
    required this.a,
    required this.counter
  });

  @override
  Component build(BuildContext context) {
    if (counter() > 0) {
      return _CellComponentTest8(a);
    }

    return div([]);
  }
}

/// Tests that the component stops observing cells when it is unmounted
///
/// This component actually observes cell [a].
///
/// [CellComponentTest8] on the other hand is just a wrapper that unmounts this
/// component to trigger disposal.
class _CellComponentTest8 extends CellComponent {
  final ValueCell<int> a;

  _CellComponentTest8(this.a);

  @override
  Component build(BuildContext context) {
    final b = MutableCell(1);
    final c = ValueCell.computed(() => a() + b());
    final d = MutableCell.computed(() => a() + b(), (value) => b.value = value);

    return text('C = ${c()}, D = ${d()}');
  }
}

/// Tests using ValueCell.watch in build method
class CellComponentTest9 extends CellComponent {
  /// Controls the building of the component
  ///
  /// If 0, the component containing the watch functions that call [listener1]
  /// and [listener2] is removed from the tree.
  final ValueCell<int> counter;

  final ValueCell<void> cell;
  final Function() listener1;
  final Function() listener2;

  const CellComponentTest9({
    super.key,
    required this.counter,
    required this.cell,
    required this.listener1,
    required this.listener2
  });

  @override
  Component build(BuildContext context) {
    if (counter() > 0) {
      return _CellComponentTest9(cell, listener1, listener2);
    }

    return div([]);
  }
}

class _CellComponentTest9 extends CellComponent {
  final ValueCell<void> cell;
  final Function() listener1;
  final Function() listener2;

  _CellComponentTest9(this.cell, this.listener1, this.listener2);

  @override
  Component build(BuildContext context) {
    ValueCell.watch(() {
      cell.observe();
      listener1();
    });

    ValueCell.watch(() {
      cell.observe();
      listener2();
    });

    return div([]);
  }
}

/// Tests using Watch in build method
class CellComponentTest10 extends CellComponent {
  /// Controls the building of the component
  ///
  /// If 0, the component containing the watch functions that call [listener1]
  /// and [listener2] is removed from the tree.
  final ValueCell<int> counter;

  final ValueCell<void> cell;
  final Function() listener1;
  final Function() listener2;

  CellComponentTest10({
    required this.counter,
    required this.cell,
    required this.listener1,
    required this.listener2
  });

  @override
  Component build(BuildContext context) {
    if (counter() > 0) {
      return _CellComponentTest10(cell, listener1, listener2);
    }

    return div([]);
  }
}

class _CellComponentTest10 extends CellComponent {
  final ValueCell<void> cell;
  final Function() listener1;
  final Function() listener2;

  const _CellComponentTest10(this.cell, this.listener1, this.listener2);

  @override
  Component build(BuildContext context) {
    Watch((_) {
      cell.observe();
      listener1();
    });

    Watch((_) {
      cell.observe();
      listener2();
    });

    return div([]);
  }
}

/// Add a listener to a cell, which is called whenever the cell changes.
///
/// This function adds a watch function that references [cell]. Unlike
/// [ValueCell.watch] the watch function is not called on the initial setup.
///
/// This function also adds a teardown to the current test which removes
/// the [listener] from [cell], after the current test runs.
T addListener<T extends SimpleListener>(ValueCell cell, T? listener) {
  listener ??= MockSimpleListener() as T?;

  var first = true;

  final watcher = ValueCell.watch(() {
    try {
      cell();
    } catch (e) {
      // Print exceptions from failing tests
      // The value is only referenced to set up the dependency. An exception
      // doesn't actually mean a test failed
    }

    if (!first) {
      listener!.call();
    }

    first = false;
  });

  addTearDown(() => watcher.stop());

  return listener!;
}

void main() {
  group('CellComponent.builder', () {
    testComponents('Rebuilt when referenced cell changes', (tester) async {
      final count = MutableCell(0);
      tester.pumpComponent(
          CellComponent.builder((context) => text('${count()}'))
      );

      expect(find.text('0'), findsOneComponent);
      expect(find.text('1'), findsNothing);

      count.value++;
      await tester.pump();

      expect(find.text('0'), findsNothing);
      expect(find.text('1'), findsOneComponent);

      count.value++;
      await tester.pump();

      expect(find.text('0'), findsNothing);
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsOneComponent);
    });

    testComponents('Rebuilt when multiple referenced cells changed', (tester) async {
      final a = MutableCell(0);
      final b = MutableCell(1);
      final sum = (a + b).store();

      tester.pumpComponent(
          CellComponent.builder((context) => text('${a()} + ${b()} = ${sum()}'))
      );

      expect(find.text('0 + 1 = 1'), findsOneComponent);

      a.value = 2;
      await tester.pump();
      expect(find.text('2 + 1 = 3'), findsOneComponent);

      MutableCell.batch(() {
        a.value = 5;
        b.value = 8;
      });

      await tester.pump();
      expect(find.text('5 + 8 = 13'), findsOneComponent);
    });

    testComponents('Cells defined in build method without .cell', (tester) async {
      tester.pumpComponent(
        CellComponent.builder((context) {
          final c1 = MutableCell(0);
          final c2 = MutableCell(10);

          return div([
            button(
                onClick: () => c1.value++,
                [text('${c1()}')]
              ),
              button(
                onClick: () => c2.value++,
                [text('${c2()}')]
              )
            ],
          );
        }),
      );

      expect(find.text('0'), findsOneComponent);
      expect(find.text('10'), findsOneComponent);

      await tester.click(find.tag('button').first);
      await tester.pump();

      expect(find.text('1'), findsOneComponent);
      expect(find.text('10'), findsOneComponent);

      await tester.click(find.tag('button').last);
      await tester.pump();

      expect(find.text('1'), findsOneComponent);
      expect(find.text('11'), findsOneComponent);

      await tester.click(find.tag('button').first);
      await tester.click(find.tag('button').last);
      await tester.pump();

      expect(find.text('2'), findsOneComponent);
      expect(find.text('12'), findsOneComponent);
    });

    testComponents('Cells defined in build method without .cell persisted between builds', (tester) async {
      tester.pumpComponent(
        CellComponent.builder((context) {
          final c1 = MutableCell(0);
          final c2 = MutableCell(10);

          return div([
            button(
                onClick: () => c1.value++,
                [text('${c1()}')]
            ),

            // This component tree is rebuilt whenever the value of c1 changes
            CellComponent.builder((_) {
              final c2 = MutableCell(10);

              return button(
                  onClick: () => c2.value++,
                  [text('${c2()}')]
              );
            })
          ]);
        }),
      );

      expect(find.text('0'), findsOneComponent);
      expect(find.text('10'), findsOneComponent);

      // Press first button
      await tester.click(find.tag('button').first);
      await tester.pump();

      expect(find.text('1'), findsOneComponent);
      expect(find.text('10'), findsOneComponent);

      // Press second button
      await tester.click(find.tag('button').last);
      await tester.pump();

      expect(find.text('1'), findsOneComponent);
      expect(find.text('11'), findsOneComponent);

      // Press first button
      await tester.click(find.tag('button').first);
      await tester.pump();

      expect(find.text('2'), findsOneComponent);
      expect(find.text('11'), findsOneComponent);

      // Press second button
      await tester.click(find.tag('button').last);
      await tester.pump();

      expect(find.text('2'), findsOneComponent);
      expect(find.text('12'), findsOneComponent);
    });

    testComponents('Conditional dependencies tracked correctly', (tester) async {
      final a = MutableCell(0);
      final b = MutableCell(1);
      final cond = MutableCell(true);

      tester.pumpComponent(
        CellComponent.builder((context) {
          final value = cond() ? a() : b();
          return text(value.toString());
        }),
      );

      expect(find.text('0'), findsOneComponent);

      a.value = 10;
      await tester.pump();
      expect(find.text('10'), findsOneComponent);

      cond.value = false;
      await tester.pump();
      expect(find.text('1'), findsOneComponent);

      b.value = 100;
      await tester.pump();
      expect(find.text('100'), findsOneComponent);

      cond.value = true;
      await tester.pump();
      expect(find.text('10'), findsOneComponent);

      a.value = 20;
      await tester.pump();
      expect(find.text('20'), findsOneComponent);
    });

    testComponents('New dependencies tracked correctly', (tester) async {
      final cond = MutableCell(true);

      final a = MutableCell(0);
      final b = MutableCell('hello');

      tester.pumpComponent(
        CellComponent.builder((context) {
          if (cond()) {
            return CellComponent.builder((_) => text('A = ${a()}'));
          }
          else {
            return CellComponent.builder((_) => text('B = ${b()}'));
          }
        }),
      );

      expect(find.text('A = 0'), findsOneComponent);

      cond.value = false;
      await tester.pump();

      expect(find.text('B = hello'), findsOneComponent);

      b.value = 'bye';
      await tester.pump();

      expect(find.text('B = bye'), findsOneComponent);
    });

    testComponents('Unused dependencies untracked', (tester) async {
      final cond = MutableCell(true);
      final tracker = MockCellStateTracker();
      final a = TestManagedCell(tracker, 0);
      final b = MutableCell('hello');

      tester.pumpComponent(
        CellComponent.builder((context) {
          if (cond()) {
            return text('A = ${a()}');
          }
          else {
            return text('B = ${b()}');
          }
        }),
      );

      expect(find.text('A = 0'), findsOneComponent);

      // Test that the dependency cell state was initialized
      verify(tracker.init()).called(1);
      verifyNever(tracker.dispose());

      cond.value = false;
      await tester.pump();

      expect(find.text('B = hello'), findsOneComponent);

      // Test that the dependency cell state was disposed
      verifyNever(tracker.init());
      verify(tracker.dispose()).called(1);
    });

    testComponents('Dependencies untracked when unmounted', (tester) async {
      final counter = MutableCell(1);

      final tracker = MockCellStateTracker();
      final a = TestManagedCell(tracker, 0);

      tester.pumpComponent(
        CellComponent.builder((context) {
          if (counter() > 0) {
            return CellComponent.builder((context) => text('A = ${a()}'));
          }

          return div([]);
        }),
      );

      expect(find.text('A = 0'), findsOneComponent);

      // Test that the dependency cell state was initialized
      verify(tracker.init()).called(1);
      verifyNever(tracker.dispose());

      counter.value = 0;
      await tester.pump();

      // Test that the dependency cell state was disposed
      verifyNever(tracker.init());
      verify(tracker.dispose()).called(1);
    });

    testComponents('Does not leak resources when unmounted', (tester) async {
      final counter = MutableCell(1);
      final tracker = MockCellStateTracker();
      final a = TestManagedCell(tracker, 0);

      tester.pumpComponent(
        CellComponent.builder((context) {
          if (counter() > 0) {
            return CellComponent.builder((context) {
              final b = MutableCell(1);
              final c = ValueCell.computed(() => a() + b());
              final d = MutableCell.computed(() => a() + b(), (value) => b.value = value);

              return text('C = ${c()}, D = ${d()}');
            });
          }

          return div([]);
        }),
      );

      expect(find.text('C = 1, D = 1'), findsOneComponent);

      // Test that the dependency cell state was initialized
      verify(tracker.init()).called(1);
      verifyNever(tracker.dispose());

      counter.value++;
      await tester.pump();

      counter.value = 0;
      await tester.pump();

      // Test that the dependency cell state was disposed
      verifyNever(tracker.init());
      verify(tracker.dispose()).called(1);
    });

    testComponents('Using ValueCell.watch in build method', (tester) async {
      final counter = MutableCell(1);
      final listener1 = MockSimpleListener();
      final listener2 = MockSimpleListener();
      final cell = ActionCell();

      tester.pumpComponent(
        CellComponent.builder((context) {
          if (counter() > 0) {
            return CellComponent.builder((context) {
              ValueCell.watch(() {
                cell.observe();
                listener1();
              });

              ValueCell.watch(() {
                cell.observe();
                listener2();
              });

              return div([]);
            });
          }

          return div([]);
        }),
      );

      verify(listener1()).called(1);
      verify(listener2()).called(1);

      cell.trigger();
      await tester.pump();

      verify(listener1()).called(1);
      verify(listener2()).called(1);

      counter.value++;
      await tester.pump();

      verifyNever(listener1());
      verifyNever(listener2());

      cell.trigger();
      await tester.pump();

      verify(listener1()).called(1);
      verify(listener2()).called(1);

      counter.value = 0;
      await tester.pump();

      cell.trigger();
      await tester.pump();

      cell.trigger();
      await tester.pump();

      verifyNever(listener1());
      verifyNever(listener2());
    });

    testComponents('Using Watch in build method', (tester) async {
      final counter = MutableCell(1);
      final listener1 = MockSimpleListener();
      final listener2 = MockSimpleListener();
      final cell = ActionCell();

      tester.pumpComponent(
        CellComponent.builder((context) {
          if (counter() > 0) {
            return CellComponent.builder((_) {
              Watch((_) {
                cell.observe();
                listener1();
              });

              Watch((_) {
                cell.observe();
                listener2();
              });

              return div([]);
            });
          }

          return div([]);
        }),
      );

      verify(listener1()).called(1);
      verify(listener2()).called(1);

      cell.trigger();
      await tester.pump();

      verify(listener1()).called(1);
      verify(listener2()).called(1);

      counter.value++;
      await tester.pump();

      verifyNever(listener1());
      verifyNever(listener2());

      cell.trigger();
      await tester.pump();

      verify(listener1()).called(1);
      verify(listener2()).called(1);

      counter.value = 0;
      await tester.pump();

      cell.trigger();
      await tester.pump();

      cell.trigger();
      await tester.pump();

      verifyNever(listener1());
      verifyNever(listener2());
    });
  });

  group('CellComponent subclass', () {
    testComponents('Rebuilt when referenced cell changes', (tester) async {
      final count = MutableCell(0);
      tester.pumpComponent(CellComponentTest1(count: count));

      expect(find.text('0'), findsOneComponent);
      expect(find.text('1'), findsNothing);

      count.value++;
      await tester.pump();

      expect(find.text('0'), findsNothing);
      expect(find.text('1'), findsOneComponent);

      count.value++;
      await tester.pump();

      expect(find.text('0'), findsNothing);
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsOneComponent);
    });

    testComponents('Rebuilt when multiple referenced cells changed', (tester) async {
      final a = MutableCell(0);
      final b = MutableCell(1);
      final sum = (a + b).store();

      tester.pumpComponent(CellComponentTest2(
        a: a,
        b: b,
        sum: sum,
      ));

      expect(find.text('0 + 1 = 1'), findsOneComponent);

      a.value = 2;
      await tester.pump();
      expect(find.text('2 + 1 = 3'), findsOneComponent);

      MutableCell.batch(() {
        a.value = 5;
        b.value = 8;
      });
      await tester.pump();
      expect(find.text('5 + 8 = 13'), findsOneComponent);
    });

    testComponents('Cells defined in build method without .cell', (tester) async {
      tester.pumpComponent(CellComponentTest5());

      expect(find.text('0'), findsOneComponent);
      expect(find.text('10'), findsOneComponent);

      await tester.click(find.tag('button').first);
      await tester.pump();

      expect(find.text('1'), findsOneComponent);
      expect(find.text('10'), findsOneComponent);

      await tester.click(find.tag('button').last);
      await tester.pump();

      expect(find.text('1'), findsOneComponent);
      expect(find.text('11'), findsOneComponent);

      await tester.click(find.tag('button').first);
      await tester.click(find.tag('button').last);
      await tester.pump();

      expect(find.text('2'), findsOneComponent);
      expect(find.text('12'), findsOneComponent);
    });

    testComponents('Cells defined in build method without .cell persisted between builds', (tester) async {
      tester.pumpComponent(CellComponentTest6());

      expect(find.text('0'), findsOneComponent);
      expect(find.text('10'), findsOneComponent);

      // Press first button
      await tester.click(find.tag('button').first);
      await tester.pump();

      expect(find.text('1'), findsOneComponent);
      expect(find.text('10'), findsOneComponent);

      // Press second button
      await tester.click(find.tag('button').last);
      await tester.pump();

      expect(find.text('1'), findsOneComponent);
      expect(find.text('11'), findsOneComponent);

      // Press first button
      await tester.click(find.tag('button').first);
      await tester.pump();

      expect(find.text('2'), findsOneComponent);
      expect(find.text('11'), findsOneComponent);

      // Press second button
      await tester.click(find.tag('button').last);
      await tester.pump();

      expect(find.text('2'), findsOneComponent);
      expect(find.text('12'), findsOneComponent);
    });

    testComponents('Does not leak resources when unmounted', (tester) async {
      final tracker = MockCellStateTracker();
      final a = TestManagedCell(tracker, 0);

      final counter = MutableCell(1);

      tester.pumpComponent(CellComponentTest8(
        counter: counter,
        a: a
      ));

      expect(find.text('C = 1, D = 1'), findsOneComponent);

      // Test that the dependency cell state was initialized
      verify(tracker.init()).called(1);
      verifyNever(tracker.dispose());

      counter.value++;
      await tester.pump();

      counter.value = 0;
      await tester.pump();

      // Test that the dependency cell state was disposed
      verifyNever(tracker.init());
      verify(tracker.dispose()).called(1);
    });

    testComponents('Using ValueCell.watch in build method', (tester) async {
      final counter = MutableCell(1);

      final listener1 = MockSimpleListener();
      final listener2 = MockSimpleListener();
      final cell = ActionCell();

      tester.pumpComponent(
          CellComponentTest9(
              counter: counter,
              cell: cell,
              listener1: listener1,
              listener2: listener2
          )
      );

      verify(listener1()).called(1);
      verify(listener2()).called(1);

      cell.trigger();
      await tester.pump();

      verify(listener1()).called(1);
      verify(listener2()).called(1);

      // Trigger a rebuild of the component tree
      counter.value++;
      await tester.pump();

      verifyNever(listener1());
      verifyNever(listener2());

      cell.trigger();
      await tester.pump();

      verify(listener1()).called(1);
      verify(listener2()).called(1);

      // Remove the component from the tree
      counter.value = 0;
      await tester.pump();

      cell.trigger();
      await tester.pump();

      cell.trigger();
      await tester.pump();

      verifyNever(listener1());
      verifyNever(listener2());
    });

    testComponents('Using Watch in build method', (tester) async {
      final counter = MutableCell(1);

      final listener1 = MockSimpleListener();
      final listener2 = MockSimpleListener();
      final cell = ActionCell();

      tester.pumpComponent(
          CellComponentTest10(
            counter: counter,
            cell: cell,
            listener1: listener1,
            listener2: listener2
          )
      );

      verify(listener1()).called(1);
      verify(listener2()).called(1);

      cell.trigger();
      await tester.pump();

      verify(listener1()).called(1);
      verify(listener2()).called(1);

      counter.value++;
      await tester.pump();

      verifyNever(listener1());
      verifyNever(listener2());

      cell.trigger();
      await tester.pump();

      verify(listener1()).called(1);
      verify(listener2()).called(1);

      counter.value = 0;
      await tester.pump();

      cell.trigger();
      await tester.pump();

      cell.trigger();
      await tester.pump();

      verifyNever(listener1());
      verifyNever(listener2());
    });
  });
}
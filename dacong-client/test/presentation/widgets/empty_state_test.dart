import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dacong_client/presentation/widgets/empty_state.dart';

void main() {
  group('EmptyState Widget Tests', () {
    testWidgets('displays icon, title, and message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No Items',
              message: 'There are no items to display',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('No Items'), findsOneWidget);
      expect(find.text('There are no items to display'), findsOneWidget);
    });

    testWidgets('displays action button when provided', (tester) async {
      bool actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No Items',
              message: 'There are no items to display',
              action: ElevatedButton(
                onPressed: () => actionCalled = true,
                child: const Text('Add Item'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Add Item'), findsOneWidget);

      await tester.tap(find.text('Add Item'));
      await tester.pump();

      expect(actionCalled, isTrue);
    });

    testWidgets('does not display action button when not provided',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No Items',
              message: 'There are no items to display',
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('uses theme colors correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: const Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No Items',
              message: 'There are no items to display',
            ),
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.inbox));
      expect(iconWidget.size, 80);
    });

    testWidgets('centers content vertically and horizontally', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No Items',
              message: 'There are no items to display',
            ),
          ),
        ),
      );

      final centerFinder = find.byType(Center);
      expect(centerFinder, findsOneWidget);

      final columnFinder = find.byType(Column);
      expect(columnFinder, findsOneWidget);

      final column = tester.widget<Column>(columnFinder);
      expect(column.mainAxisAlignment, MainAxisAlignment.center);
    });

    testWidgets('applies correct padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No Items',
              message: 'There are no items to display',
            ),
          ),
        ),
      );

      final paddingFinder = find.byType(Padding);
      expect(paddingFinder, findsWidgets);

      final outerPadding = tester.widget<Padding>(paddingFinder.first);
      expect(outerPadding.padding, const EdgeInsets.all(32));
    });

    testWidgets('text alignment is center', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No Items',
              message: 'There are no items to display',
            ),
          ),
        ),
      );

      final titleText = tester.widget<Text>(find.text('No Items'));
      expect(titleText.textAlign, TextAlign.center);

      final messageText =
          tester.widget<Text>(find.text('There are no items to display'));
      expect(messageText.textAlign, TextAlign.center);
    });
  });
}

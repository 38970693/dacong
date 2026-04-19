import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dacong_client/core/utils/toast_helper.dart';

void main() {
  group('ToastHelper Tests', () {
    testWidgets('showSuccess displays success toast', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ToastHelper.showSuccess(context, 'Success message');
                  },
                  child: const Text('Show Success'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Success message'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('showError displays error toast', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ToastHelper.showError(context, 'Error message');
                  },
                  child: const Text('Show Error'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Error message'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('showWarning displays warning toast', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ToastHelper.showWarning(context, 'Warning message');
                  },
                  child: const Text('Show Warning'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Warning'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Warning message'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('showInfo displays info toast', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ToastHelper.showInfo(context, 'Info message');
                  },
                  child: const Text('Show Info'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Info'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Info message'), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('show displays plain toast', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ToastHelper.show(context, 'Plain message');
                  },
                  child: const Text('Show Plain'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Plain'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Plain message'), findsOneWidget);
    });

    testWidgets('showLoading displays loading toast', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ToastHelper.showLoading(context, 'Loading...');
                  },
                  child: const Text('Show Loading'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Loading'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Loading...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hide removes current toast', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        ToastHelper.show(context, 'Test message');
                      },
                      child: const Text('Show Toast'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ToastHelper.hide(context);
                      },
                      child: const Text('Hide Toast'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Test message'), findsOneWidget);

      await tester.tap(find.text('Hide Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Test message'), findsNothing);
    });

    testWidgets('showWithAction displays toast with action button',
        (tester) async {
      bool actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ToastHelper.showWithAction(
                      context,
                      'Message with action',
                      actionLabel: 'Undo',
                      onAction: () => actionCalled = true,
                    );
                  },
                  child: const Text('Show With Action'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show With Action'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Message with action'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pump();

      expect(actionCalled, isTrue);
    });
  });

  group('CustomToast Tests', () {
    testWidgets('show displays custom toast', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    CustomToast.show(context, 'Custom toast message');
                  },
                  child: const Text('Show Custom Toast'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Custom Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Custom toast message'), findsOneWidget);
    });

    testWidgets('show with top position', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    CustomToast.show(
                      context,
                      'Top toast',
                      position: ToastPosition.top,
                    );
                  },
                  child: const Text('Show Top Toast'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Top Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Top toast'), findsOneWidget);
    });

    testWidgets('show with center position', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    CustomToast.show(
                      context,
                      'Center toast',
                      position: ToastPosition.center,
                    );
                  },
                  child: const Text('Show Center Toast'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Center Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Center toast'), findsOneWidget);
    });

    testWidgets('show with custom colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    CustomToast.show(
                      context,
                      'Colored toast',
                      backgroundColor: Colors.blue,
                      textColor: Colors.white,
                    );
                  },
                  child: const Text('Show Colored Toast'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Colored Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Colored toast'), findsOneWidget);
    });

    testWidgets('hide removes custom toast', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        CustomToast.show(context, 'Test toast');
                      },
                      child: const Text('Show Toast'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        CustomToast.hide();
                      },
                      child: const Text('Hide Toast'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Test toast'), findsOneWidget);

      CustomToast.hide();
      await tester.pump();

      expect(find.text('Test toast'), findsNothing);
    });
  });
}

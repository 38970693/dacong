import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dacong_client/presentation/widgets/content_detail/pros_cons_list.dart';

void main() {
  group('ProsConsList', () {
    testWidgets('displays pros list', (tester) async {
      const pros = ['Pro 1', 'Pro 2', 'Pro 3'];
      const cons = <String>[];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProsConsList(
              pros: pros,
              cons: cons,
            ),
          ),
        ),
      );

      expect(find.text('优点'), findsOneWidget);
      expect(find.text('Pro 1'), findsOneWidget);
      expect(find.text('Pro 2'), findsOneWidget);
      expect(find.text('Pro 3'), findsOneWidget);
    });

    testWidgets('displays cons list', (tester) async {
      const pros = <String>[];
      const cons = ['Con 1', 'Con 2'];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProsConsList(
              pros: pros,
              cons: cons,
            ),
          ),
        ),
      );

      expect(find.text('缺点'), findsOneWidget);
      expect(find.text('Con 1'), findsOneWidget);
      expect(find.text('Con 2'), findsOneWidget);
    });

    testWidgets('displays both pros and cons', (tester) async {
      const pros = ['Pro 1', 'Pro 2'];
      const cons = ['Con 1'];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProsConsList(
              pros: pros,
              cons: cons,
            ),
          ),
        ),
      );

      expect(find.text('优点'), findsOneWidget);
      expect(find.text('缺点'), findsOneWidget);
      expect(find.text('Pro 1'), findsOneWidget);
      expect(find.text('Pro 2'), findsOneWidget);
      expect(find.text('Con 1'), findsOneWidget);
    });

    testWidgets('displays empty message when no pros and cons', (tester) async {
      const pros = <String>[];
      const cons = <String>[];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProsConsList(
              pros: pros,
              cons: cons,
            ),
          ),
        ),
      );

      expect(find.text('暂无优缺点信息'), findsOneWidget);
    });

    testWidgets('displays check icon for pros', (tester) async {
      const pros = ['Pro 1'];
      const cons = <String>[];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProsConsList(
              pros: pros,
              cons: cons,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });

    testWidgets('displays cancel icon for cons', (tester) async {
      const pros = <String>[];
      const cons = ['Con 1'];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProsConsList(
              pros: pros,
              cons: cons,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
    });
  });
}

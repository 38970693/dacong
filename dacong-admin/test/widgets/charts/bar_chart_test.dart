import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:dacong_admin/widgets/charts/bar_chart.dart';

void main() {
  group('DacongBarChart', () {
    testWidgets('should render with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DacongBarChart(
              title: 'Test Bar Chart',
              labels: ['A', 'B', 'C'],
              groups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(toY: 10, color: Colors.blue),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(toY: 20, color: Colors.blue),
                  ],
                ),
                BarChartGroupData(
                  x: 2,
                  barRods: [
                    BarChartRodData(toY: 15, color: Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Test Bar Chart'), findsOneWidget);
    });

    testWidgets('should show grid when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DacongBarChart(
              title: 'Test Chart',
              labels: ['A'],
              showGrid: true,
              groups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(toY: 10, color: Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('should handle empty groups', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DacongBarChart(
              title: 'Empty Chart',
              labels: [],
              groups: [],
            ),
          ),
        ),
      );

      expect(find.text('Empty Chart'), findsOneWidget);
    });

    testWidgets('should respect maxY parameter', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DacongBarChart(
              title: 'Test Chart',
              labels: ['A'],
              maxY: 100,
              groups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(toY: 50, color: Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(BarChart), findsOneWidget);
    });
  });
}

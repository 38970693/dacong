import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:dacong_admin/widgets/charts/line_chart.dart' as custom;

void main() {
  group('DacongLineChart', () {
    testWidgets('should render with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: custom.DacongLineChart(
              title: 'Test Line Chart',
              labels: ['1', '2', '3'],
              datasets: [
                custom.LineChartDataset(
                  label: 'Series 1',
                  spots: [
                    const FlSpot(0, 10),
                    const FlSpot(1, 20),
                    const FlSpot(2, 15),
                  ],
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Test Line Chart'), findsOneWidget);
    });

    testWidgets('should show legend', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: custom.DacongLineChart(
              title: 'Test Chart',
              labels: ['1', '2'],
              datasets: [
                custom.LineChartDataset(
                  label: 'Series 1',
                  spots: [
                    const FlSpot(0, 10),
                    const FlSpot(1, 20),
                  ],
                  color: Colors.blue,
                ),
                custom.LineChartDataset(
                  label: 'Series 2',
                  spots: [
                    const FlSpot(0, 15),
                    const FlSpot(1, 25),
                  ],
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Series 1'), findsOneWidget);
      expect(find.text('Series 2'), findsOneWidget);
    });

    testWidgets('should handle empty datasets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: custom.DacongLineChart(
              title: 'Empty Chart',
              labels: [],
              datasets: [],
            ),
          ),
        ),
      );

      expect(find.text('Empty Chart'), findsOneWidget);
    });

    testWidgets('should show grid when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: custom.DacongLineChart(
              title: 'Test Chart',
              labels: ['1'],
              showGrid: true,
              datasets: [
                custom.LineChartDataset(
                  label: 'Series 1',
                  spots: [const FlSpot(0, 10)],
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('should respect minY and maxY', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: custom.DacongLineChart(
              title: 'Test Chart',
              labels: ['1'],
              minY: 0,
              maxY: 100,
              datasets: [
                custom.LineChartDataset(
                  label: 'Series 1',
                  spots: [const FlSpot(0, 50)],
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(LineChart), findsOneWidget);
    });
  });
}

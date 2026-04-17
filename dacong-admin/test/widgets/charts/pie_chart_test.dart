import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:dacong_admin/widgets/charts/pie_chart.dart';

void main() {
  group('DacongPieChart', () {
    testWidgets('should render with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DacongPieChart(
              title: 'Test Chart',
              sections: [
                PieChartSectionData(
                  value: 50,
                  title: 'Section 1',
                  color: Colors.blue,
                ),
                PieChartSectionData(
                  value: 50,
                  title: 'Section 2',
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Test Chart'), findsOneWidget);
    });

    testWidgets('should show legend when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DacongPieChart(
              title: 'Test Chart',
              showLegend: true,
              sections: [
                PieChartSectionData(
                  value: 50,
                  title: 'Section 1',
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Section 1'), findsWidgets);
    });

    testWidgets('should hide legend when disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DacongPieChart(
              title: 'Test Chart',
              showLegend: false,
              sections: [
                PieChartSectionData(
                  value: 50,
                  title: 'Section 1',
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Legend should not be visible
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('should handle empty sections', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DacongPieChart(
              title: 'Empty Chart',
              sections: [],
            ),
          ),
        ),
      );

      expect(find.text('Empty Chart'), findsOneWidget);
    });
  });
}

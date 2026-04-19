import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DacongLineChart extends StatefulWidget {
  final List<LineChartDataset> datasets;
  final String title;
  final List<String> labels;
  final bool showGrid;
  final bool enableZoom;
  final double? minY;
  final double? maxY;

  const DacongLineChart({
    super.key,
    required this.datasets,
    required this.title,
    required this.labels,
    this.showGrid = true,
    this.enableZoom = true,
    this.minY,
    this.maxY,
  });

  @override
  State<DacongLineChart> createState() => _DacongLineChartState();
}

class _DacongLineChartState extends State<DacongLineChart> {
  double _scale = 1.0;
  double _previousScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: widget.enableZoom
                  ? GestureDetector(
                      onScaleStart: (details) {
                        _previousScale = _scale;
                      },
                      onScaleUpdate: (details) {
                        setState(() {
                          _scale = (_previousScale * details.scale).clamp(0.5, 3.0);
                        });
                      },
                      child: _buildChart(isDark),
                    )
                  : _buildChart(isDark),
            ),
            const SizedBox(height: 16),
            _buildLegend(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(bool isDark) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: widget.showGrid,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < widget.labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.labels[index],
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
          ),
        ),
        minX: 0,
        maxX: (widget.labels.length - 1).toDouble(),
        minY: widget.minY ?? 0,
        maxY: widget.maxY,
        lineBarsData: widget.datasets.map((dataset) {
          return LineChartBarData(
            spots: dataset.spots,
            isCurved: true,
            color: dataset.color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: dataset.color,
                  strokeWidth: 2,
                  strokeColor: isDark ? Colors.black : Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: dataset.color.withOpacity(0.1),
            ),
          );
        }).toList(),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final dataset = widget.datasets[spot.barIndex];
                return LineTooltipItem(
                  '${dataset.label}\n${spot.y.toStringAsFixed(1)}',
                  TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(bool isDark) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: widget.datasets.map((dataset) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: dataset.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              dataset.label,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class LineChartDataset {
  final String label;
  final List<FlSpot> spots;
  final Color color;

  LineChartDataset({
    required this.label,
    required this.spots,
    required this.color,
  });
}

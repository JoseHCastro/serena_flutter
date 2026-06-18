import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/analysis_model.dart';
import '../theme/app_theme.dart';

const _emotionColors = {
  'happiness': Colors.amber,
  'sadness': AppTheme.secondaryColor,
  'anger': AppTheme.errorColor,
  'fear': Colors.purple,
  'disgust': Colors.green,
  'surprise': Colors.orange,
  'neutral': AppTheme.textMuted,
};

const _emotionLabels = {
  'happiness': 'Felicidad',
  'sadness': 'Tristeza',
  'anger': 'Enojo',
  'fear': 'Miedo',
  'disgust': 'Asco',
  'surprise': 'Sorpresa',
  'neutral': 'Neutral',
};

class EmotionTimelineChart extends StatelessWidget {
  final List<EmotionalSnapshot> snapshots;

  const EmotionTimelineChart({super.key, required this.snapshots});

  @override
  Widget build(BuildContext context) {
    if (snapshots.isEmpty) {
      return const Center(child: Text('Sin datos de análisis'));
    }

    final lines = _buildLines();
    final maxX = snapshots.last.timestampOffset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timeline emocional',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 1,
              minX: 0,
              maxX: maxX,
              lineBarsData: lines,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: maxX > 60 ? 60 : maxX / 4,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}s',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 0.5,
                    getTitlesWidget: (value, meta) => Text(
                      '${(value * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: AppTheme.borderColor),
              ),
              lineTouchData: const LineTouchData(enabled: true),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        _Legend(),
      ],
    );
  }

  List<LineChartBarData> _buildLines() {
    final emotions = _emotionColors.keys.toList();
    return emotions.map((emotion) {
      final spots = snapshots.map((s) {
        final y = s.allEmotions[emotion] ?? 0.0;
        return FlSpot(s.timestampOffset, y);
      }).toList();

      return LineChartBarData(
        spots: spots,
        color: _emotionColors[emotion],
        barWidth: 1.5,
        dotData: const FlDotData(show: false),
        isCurved: true,
        curveSmoothness: 0.3,
        preventCurveOverShooting: true,
      );
    }).toList();
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.spacingMd,
      runSpacing: AppTheme.spacingSm,
      children: _emotionColors.entries.map((e) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: e.value,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _emotionLabels[e.key] ?? e.key,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class EmotionAverageChart extends StatelessWidget {
  final List<EmotionalSnapshot> snapshots;

  const EmotionAverageChart({super.key, required this.snapshots});

  @override
  Widget build(BuildContext context) {
    if (snapshots.isEmpty) return const SizedBox.shrink();

    final averages = _computeAverages();
    final emotions = averages.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Promedio por emoción',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: 1,
              barGroups: emotions.asMap().entries.map((entry) {
                final emotion = entry.value;
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: averages[emotion]!,
                      color: _emotionColors[emotion] ?? AppTheme.textMuted,
                      width: 18,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final emotion = emotions[value.toInt()];
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          (_emotionLabels[emotion] ?? emotion).substring(0, 3),
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 0.5,
                    getTitlesWidget: (value, meta) => Text(
                      '${(value * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  Map<String, double> _computeAverages() {
    final emotions = _emotionColors.keys.toList();
    return {
      for (final e in emotions)
        e: snapshots.map((s) => s.allEmotions[e] ?? 0.0).reduce((a, b) => a + b) /
            snapshots.length,
    };
  }
}

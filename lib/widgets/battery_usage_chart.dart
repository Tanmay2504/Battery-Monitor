import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/battery_usage.dart';

class BatteryUsageChart extends StatelessWidget {
  final List<BatteryUsage> usageData;
  final String title;
  
  const BatteryUsageChart({
    Key? key,
    required this.usageData,
    this.title = 'Battery Level History',
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Sort data by timestamp
    final sortedData = List<BatteryUsage>.from(usageData)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Last ${sortedData.length} records',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: sortedData.length < 2
              ? Center(
                  child: Text(
                    'Not enough data to show chart',
                    style: GoogleFonts.poppins(color: Colors.grey.shade600),
                  ),
                )
              : LineChart(_buildLineChartData(sortedData, context)),
          ),
        ],
      ),
    );
  }
  
  LineChartData _buildLineChartData(List<BatteryUsage> data, BuildContext context) {
    // Prepare data points
    List<FlSpot> batteryLevelSpots = [];
    
    for (int i = 0; i < data.length; i++) {
      batteryLevelSpots.add(FlSpot(i.toDouble(), data[i].batteryLevel.toDouble()));
    }
    
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 25,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value.toInt() % (data.length ~/ 4 + 1) != 0) {
                return const SizedBox.shrink();
              }
              
              int index = value.toInt();
              if (index >= 0 && index < data.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    data[index].getFormattedTime().split(' - ')[0], // Just show hour
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              if (value % 25 != 0) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  '${value.toInt()}%',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Theme.of(context).colorScheme.surfaceVariant,
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final int index = barSpot.x.toInt();
              if (index >= 0 && index < data.length) {
                return LineTooltipItem(
                  '${data[index].batteryLevel}%\n',
                  GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: data[index].getFormattedTime(),
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }
              return null;
            }).toList();
          },
        ),
      ),
      minY: 0,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: batteryLevelSpots,
          isCurved: true,
          color: Theme.of(context).colorScheme.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ),
        ),
      ],
    );
  }
} 
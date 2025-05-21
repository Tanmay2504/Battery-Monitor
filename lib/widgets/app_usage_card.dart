import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_usage_data.dart';

class AppUsageCard extends StatelessWidget {
  final AppUsageData usageData;
  final int index;
  
  const AppUsageCard({
    Key? key,
    required this.usageData,
    required this.index,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            _buildRank(),
            _buildAppIcon(),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAppInfo(),
            ),
            _buildBatteryUsage(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRank() {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: _getRankColor(index),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Widget _buildAppIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getRandomColor(usageData.appName.hashCode),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          usageData.appName.isNotEmpty ? usageData.appName[0].toUpperCase() : '?',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
  
  Widget _buildAppInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          usageData.appName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Used for ${usageData.getFormattedUsageTime()}',
          style: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildBatteryUsage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${usageData.batteryConsumptionPercentage.toStringAsFixed(1)}%',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: _getUsageColor(usageData.batteryConsumptionPercentage),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Battery Used',
          style: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.amber;
      default:
        return Colors.blue.shade300;
    }
  }
  
  Color _getUsageColor(double percentage) {
    if (percentage > 5.0) {
      return Colors.red;
    } else if (percentage > 2.0) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
  
  Color _getRandomColor(int seed) {
    final List<Color> colors = [
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.cyan,
      Colors.pink,
      Colors.deepOrange,
    ];
    
    return colors[seed % colors.length];
  }
} 
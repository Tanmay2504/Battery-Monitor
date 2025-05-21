import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/battery_usage.dart';

class BatteryStatusView extends StatelessWidget {
  final BatteryUsage batteryUsage;
  
  const BatteryStatusView({
    Key? key,
    required this.batteryUsage,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Battery Status',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBatteryCircle(),
                _buildBatteryInfo(),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBatteryCircle() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: batteryUsage.batteryLevel / 100,
              strokeWidth: 12,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getBatteryColor(batteryUsage.batteryLevel),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${batteryUsage.batteryLevel}%',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getBatteryStateText(batteryUsage.batteryState),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBatteryInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoItem(
          icon: Icons.trending_down,
          label: 'Discharge Rate',
          value: '${batteryUsage.dischargeRate.toStringAsFixed(2)}%/min',
          color: Colors.orange,
        ),
        const SizedBox(height: 16),
        _buildInfoItem(
          icon: Icons.trending_up,
          label: 'Charge Rate',
          value: '${batteryUsage.chargeRate.toStringAsFixed(2)}%/min',
          color: Colors.green,
        ),
        const SizedBox(height: 16),
        _buildInfoItem(
          icon: Icons.access_time,
          label: 'Last Updated',
          value: batteryUsage.getFormattedTime(),
          color: Colors.blue,
        ),
      ],
    );
  }
  
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Color _getBatteryColor(int level) {
    if (level <= 20) {
      return Colors.red;
    } else if (level <= 50) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
  
  String _getBatteryStateText(String state) {
    switch (state) {
      case 'charging':
        return 'Charging';
      case 'full':
        return 'Full';
      case 'discharging':
        return 'Discharging';
      default:
        return state;
    }
  }
} 
import 'package:intl/intl.dart';

class BatteryUsage {
  final int id;
  final int batteryLevel;
  final String batteryState;
  final double chargeRate;
  final double dischargeRate;
  final DateTime timestamp;
  final Map<String, double> appUsage; // App name -> percentage of battery used

  BatteryUsage({
    this.id = 0,
    required this.batteryLevel,
    required this.batteryState,
    required this.timestamp,
    this.chargeRate = 0.0,
    this.dischargeRate = 0.0,
    required this.appUsage,
  });

  Map<String, dynamic> toMap({bool forInsert = false}) {
    final map = {
      'batteryLevel': batteryLevel,
      'batteryState': batteryState,
      'chargeRate': chargeRate,
      'dischargeRate': dischargeRate,
      'timestamp': timestamp.toIso8601String(),
      'appUsage': appUsage.toString(),
    };
    if (!forInsert && id != 0) {
      map['id'] = id;
    }
    return map;
  }

  factory BatteryUsage.fromMap(Map<String, dynamic> map) {
    // Simplified parsing for demonstration
    Map<String, double> parsedAppUsage = {};
    String appUsageStr = map['appUsage'] as String;
    if (appUsageStr.length > 2) {
      // Remove the curly braces
      appUsageStr = appUsageStr.substring(1, appUsageStr.length - 1);
      // Split by comma and process each entry
      List<String> entries = appUsageStr.split(', ');
      for (var entry in entries) {
        List<String> keyValue = entry.split(': ');
        if (keyValue.length == 2) {
          parsedAppUsage[keyValue[0]] = double.tryParse(keyValue[1]) ?? 0.0;
        }
      }
    }

    return BatteryUsage(
      id: map['id'] as int,
      batteryLevel: map['batteryLevel'] as int,
      batteryState: map['batteryState'] as String,
      chargeRate: map['chargeRate'] as double,
      dischargeRate: map['dischargeRate'] as double,
      timestamp: DateTime.parse(map['timestamp'] as String),
      appUsage: parsedAppUsage,
    );
  }

  String getFormattedTime() {
    return DateFormat('HH:mm - dd MMM').format(timestamp);
  }

  String getFormattedDate() {
    return DateFormat('dd MMM yyyy').format(timestamp);
  }
} 
import 'package:intl/intl.dart';

class AppUsageData {
  final String packageName;
  final String appName;
  final Duration usageDuration;
  final DateTime startTime;
  final DateTime endTime;
  final double batteryConsumptionPercentage;
  final String? appIcon; // Optional path to app icon

  AppUsageData({
    required this.packageName,
    required this.appName,
    required this.usageDuration,
    required this.startTime,
    required this.endTime,
    this.batteryConsumptionPercentage = 0.0,
    this.appIcon,
  });

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'usageDuration': usageDuration.inSeconds,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'batteryConsumptionPercentage': batteryConsumptionPercentage,
      'appIcon': appIcon,
    };
  }

  factory AppUsageData.fromMap(Map<String, dynamic> map) {
    return AppUsageData(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      usageDuration: Duration(seconds: map['usageDuration'] as int),
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: DateTime.parse(map['endTime'] as String),
      batteryConsumptionPercentage: map['batteryConsumptionPercentage'] as double,
      appIcon: map['appIcon'] as String?,
    );
  }

  String getFormattedUsageTime() {
    int hours = usageDuration.inHours;
    int minutes = usageDuration.inMinutes % 60;
    int seconds = usageDuration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String getFormattedDateRange() {
    final DateFormat formatter = DateFormat('MMM dd, HH:mm');
    return '${formatter.format(startTime)} - ${formatter.format(endTime)}';
  }
} 
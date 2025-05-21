import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/battery_usage.dart';
import '../models/app_usage_data.dart';
import 'database_service.dart';

class BatteryMonitorService {
  static final BatteryMonitorService _instance = BatteryMonitorService._internal();
  factory BatteryMonitorService() => _instance;

  final Battery _battery = Battery();
  final DatabaseService _databaseService = DatabaseService();
  Timer? _monitorTimer;
  
  int _lastBatteryLevel = 0;
  DateTime _lastCheckedTime = DateTime.now();
  bool _isMonitoring = false;
  StreamController<BatteryUsage> _batteryStreamController = StreamController<BatteryUsage>.broadcast();
  
  Stream<BatteryUsage> get batteryStream => _batteryStreamController.stream;
  
  BatteryMonitorService._internal();

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    
    // Initialize with dummy data for demo
    await _databaseService.addDummyDataIfEmpty();
    
    if (kIsWeb) {
      // Use simulated data for web
      _lastBatteryLevel = 78;
    } else {
      _lastBatteryLevel = await _battery.batteryLevel;
    }
    
    _lastCheckedTime = DateTime.now();
    
    // Check battery every minute
    _monitorTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _checkBatteryAndApps();
    });
    
    // Immediately check once
    await _checkBatteryAndApps();
  }

  void stopMonitoring() {
    _monitorTimer?.cancel();
    _isMonitoring = false;
  }

  Future<void> _checkBatteryAndApps() async {
    int currentBatteryLevel;
    String batteryState;
    
    if (kIsWeb) {
      // Simulate battery data for web
      final random = Random();
      // Decrease battery by 0-2% each minute (simulate usage)
      currentBatteryLevel = max(0, _lastBatteryLevel - random.nextInt(3));
      batteryState = 'discharging';
    } else {
      // Get real battery data on mobile
      currentBatteryLevel = await _battery.batteryLevel;
      batteryState = (await _battery.batteryState).toString().split('.').last;
    }
    
    final DateTime now = DateTime.now();
    
    // Calculate discharge/charge rate
    final Duration timeDifference = now.difference(_lastCheckedTime);
    final double minutesElapsed = timeDifference.inSeconds / 60;
    double chargeRate = 0.0;
    double dischargeRate = 0.0;
    
    if (minutesElapsed > 0) {
      final int levelDifference = currentBatteryLevel - _lastBatteryLevel;
      
      if (levelDifference > 0) {
        // Battery is charging
        chargeRate = levelDifference / minutesElapsed;
      } else if (levelDifference < 0) {
        // Battery is discharging
        dischargeRate = (-levelDifference) / minutesElapsed;
      }
    }
    
    // Get app usage
    Map<String, double> appUsageMap = await _getAppUsageData();
    
    // Create battery usage record
    final batteryUsage = BatteryUsage(
      batteryLevel: currentBatteryLevel,
      batteryState: batteryState,
      chargeRate: chargeRate,
      dischargeRate: dischargeRate,
      timestamp: now,
      appUsage: appUsageMap,
    );
    
    // Save to database
    await _databaseService.insertBatteryUsage(batteryUsage);
    
    // Update values for next check
    _lastBatteryLevel = currentBatteryLevel;
    _lastCheckedTime = now;
    
    // Broadcast the new data
    _batteryStreamController.add(batteryUsage);
  }

  Future<Map<String, double>> _getAppUsageData() async {
    // Simulate app usage data
    final apps = {
      'Browser': 0.1 + Random().nextDouble() * 0.3,
      'Social Media': 0.1 + Random().nextDouble() * 0.5,
      'Messages': 0.05 + Random().nextDouble() * 0.15,
      'Maps': 0.2 + Random().nextDouble() * 0.4,
      'Camera': 0.1 + Random().nextDouble() * 0.2,
    };
    
    // Save each app's usage data
    for (var entry in apps.entries) {
      await _saveSimulatedAppUsage(entry.key, entry.value);
    }
    
    return apps;
  }
  
  Future<void> _saveSimulatedAppUsage(String appName, double batteryConsumption) async {
    // Create random usage duration between 5 and 60 minutes
    final minutes = 5 + Random().nextInt(55);
    final duration = Duration(minutes: minutes);
    
    AppUsageData appUsage = AppUsageData(
      packageName: 'com.example.$appName'.toLowerCase().replaceAll(' ', ''),
      appName: appName,
      usageDuration: duration,
      startTime: DateTime.now().subtract(duration + const Duration(minutes: 5)),
      endTime: DateTime.now().subtract(const Duration(minutes: 5)),
      batteryConsumptionPercentage: batteryConsumption,
    );
    
    await _databaseService.insertAppUsage(appUsage);
  }

  Future<bool> checkPermissions() async {
    // Since we're using simulated data, no permissions needed
    return true;
  }
  
  Future<String> getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    
    if (kIsWeb) {
      WebBrowserInfo webInfo = await deviceInfo.webBrowserInfo;
      return '${webInfo.browserName} on ${webInfo.platform}';
    } else if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return '${androidInfo.manufacturer} ${androidInfo.model}';
    } else {
      return 'Unknown Device';
    }
  }
} 
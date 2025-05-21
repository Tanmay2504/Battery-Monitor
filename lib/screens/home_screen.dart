import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import '../models/battery_usage.dart';
import '../services/battery_monitor_service.dart';
import '../services/database_service.dart';
import '../widgets/battery_status_view.dart';
import '../widgets/battery_usage_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BatteryMonitorService _monitorService = BatteryMonitorService();
  final DatabaseService _databaseService = DatabaseService();
  StreamSubscription<BatteryUsage>? _batterySubscription;
  
  BatteryUsage? _currentBatteryUsage;
  List<BatteryUsage> _batteryHistory = [];
  String _deviceName = 'Android Device';
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _initializeMonitoring();
  }
  
  Future<void> _initializeMonitoring() async {
    try {
      // Load data from database
      await _loadData();
      
      // Get device name
      _deviceName = await _monitorService.getDeviceInfo();
      
      // Start monitoring
      await _monitorService.startMonitoring();
      
      // Listen for battery updates
      _batterySubscription = _monitorService.batteryStream.listen((batteryUsage) {
        if (mounted) {
          setState(() {
            _currentBatteryUsage = batteryUsage;
            _batteryHistory.add(batteryUsage);
            // Limit history to most recent 24 hours (or 144 points if checking every 10 minutes)
            if (_batteryHistory.length > 144) {
              _batteryHistory.removeAt(0);
            }
          });
        }
      });
      
      // Set loading to false
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing monitoring: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }
  
  Future<void> _loadData() async {
    try {
      // Get the last 24 hours of battery data
      final DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
      List<BatteryUsage> batteryData = await _databaseService.getBatteryUsageForDay(yesterday);
      
      // Add today's data
      batteryData.addAll(await _databaseService.getBatteryUsageForDay(DateTime.now()));
      
      if (mounted) {
        setState(() {
          _batteryHistory = batteryData;
          
          // If we have at least one battery record, use the most recent as current
          if (batteryData.isNotEmpty) {
            batteryData.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            _currentBatteryUsage = batteryData.first;
          }
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      // Create dummy data for demonstration
      if (mounted) {
        setState(() {
          _currentBatteryUsage = BatteryUsage(
            batteryLevel: 78,
            batteryState: 'discharging',
            timestamp: DateTime.now(),
            appUsage: {'Browser': 2.5, 'Maps': 1.8, 'Messages': 0.5},
          );
        });
      }
    }
  }
  
  @override
  void dispose() {
    _batterySubscription?.cancel();
    _monitorService.stopMonitoring();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Battery Monitor',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDeviceInfo(),
                        if (_currentBatteryUsage != null)
                          BatteryStatusView(batteryUsage: _currentBatteryUsage!),
                        if (_batteryHistory.length >= 2)
                          BatteryUsageChart(usageData: _batteryHistory),
                      ],
                    ),
                  ),
                ),
    );
  }
  
  Widget _buildDeviceInfo() {
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
      child: Row(
        children: [
          Icon(
            Icons.phone_android,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _deviceName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last updated: ${_currentBatteryUsage?.timestamp.toString() ?? 'Never'}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeMonitoring,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
} 
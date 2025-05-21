import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/battery_usage.dart';
import '../models/app_usage_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  
  // In-memory storage for web platform
  static List<BatteryUsage> _batteryUsageCache = [];
  static List<AppUsageData> _appUsageCache = [];

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<dynamic> get database async {
    if (kIsWeb) {
      // For web, we'll use shared preferences to simulate database
      await _loadCachedData();
      return null;
    } else {
      // For mobile, use SQLite
      if (_database != null) return _database!;
      _database = await _initDatabase();
      return _database!;
    }
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'battery_monitor.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE battery_usage(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        batteryLevel INTEGER NOT NULL,
        batteryState TEXT NOT NULL,
        chargeRate REAL NOT NULL,
        dischargeRate REAL NOT NULL,
        timestamp TEXT NOT NULL,
        appUsage TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_usage(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        packageName TEXT NOT NULL,
        appName TEXT NOT NULL,
        usageDuration INTEGER NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        batteryConsumptionPercentage REAL NOT NULL,
        appIcon TEXT
      )
    ''');
  }

  // Load cached data from shared preferences for web
  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load battery usage data
    final batteryUsageJson = prefs.getStringList('batteryUsage') ?? [];
    _batteryUsageCache = batteryUsageJson
        .map((json) => BatteryUsage.fromMap(jsonDecode(json)))
        .toList();
    
    // Load app usage data
    final appUsageJson = prefs.getStringList('appUsage') ?? [];
    _appUsageCache = appUsageJson
        .map((json) => AppUsageData.fromMap(jsonDecode(json)))
        .toList();
  }

  // Save cached data to shared preferences for web
  Future<void> _saveCachedData() async {
    if (!kIsWeb) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Save battery usage data
    final batteryUsageJson = _batteryUsageCache
        .map((usage) => jsonEncode(usage.toMap()))
        .toList();
    await prefs.setStringList('batteryUsage', batteryUsageJson);
    
    // Save app usage data
    final appUsageJson = _appUsageCache
        .map((usage) => jsonEncode(usage.toMap()))
        .toList();
    await prefs.setStringList('appUsage', appUsageJson);
  }

  // Battery Usage CRUD Operations
  Future<int> insertBatteryUsage(BatteryUsage usage) async {
    await database;
    
    if (kIsWeb) {
      // For web, store in memory
      final newUsage = BatteryUsage(
        id: _batteryUsageCache.length + 1,
        batteryLevel: usage.batteryLevel,
        batteryState: usage.batteryState,
        chargeRate: usage.chargeRate,
        dischargeRate: usage.dischargeRate,
        timestamp: usage.timestamp,
        appUsage: usage.appUsage,
      );
      
      _batteryUsageCache.add(newUsage);
      await _saveCachedData();
      return newUsage.id;
    } else {
      // For mobile, use SQLite
      Database db = await database;
      return await db.insert('battery_usage', usage.toMap(forInsert: true));
    }
  }

  Future<List<BatteryUsage>> getBatteryUsage() async {
    await database;
    
    if (kIsWeb) {
      return _batteryUsageCache;
    } else {
      Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query('battery_usage');
      return List.generate(maps.length, (i) {
        return BatteryUsage.fromMap(maps[i]);
      });
    }
  }

  Future<List<BatteryUsage>> getBatteryUsageForDay(DateTime day) async {
    await database;
    
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);
    
    if (kIsWeb) {
      return _batteryUsageCache
          .where((usage) => 
              usage.timestamp.isAfter(startOfDay) && 
              usage.timestamp.isBefore(endOfDay))
          .toList();
    } else {
      Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'battery_usage',
        where: 'timestamp BETWEEN ? AND ?',
        whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      );

      return List.generate(maps.length, (i) {
        return BatteryUsage.fromMap(maps[i]);
      });
    }
  }

  // App Usage CRUD Operations
  Future<int> insertAppUsage(AppUsageData usage) async {
    await database;
    
    if (kIsWeb) {
      // Generate dummy ID for web
      _appUsageCache.add(usage);
      await _saveCachedData();
      return _appUsageCache.length;
    } else {
      Database db = await database;
      return await db.insert('app_usage', usage.toMap());
    }
  }

  Future<List<AppUsageData>> getAppUsage() async {
    await database;
    
    if (kIsWeb) {
      return _appUsageCache;
    } else {
      Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query('app_usage');
      return List.generate(maps.length, (i) {
        return AppUsageData.fromMap(maps[i]);
      });
    }
  }

  Future<List<AppUsageData>> getTopBatteryConsumingApps(int limit) async {
    await database;
    
    if (kIsWeb) {
      final sortedApps = List<AppUsageData>.from(_appUsageCache)
        ..sort((a, b) => b.batteryConsumptionPercentage.compareTo(a.batteryConsumptionPercentage));
      
      return sortedApps.take(limit).toList();
    } else {
      Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'app_usage',
        orderBy: 'batteryConsumptionPercentage DESC',
        limit: limit,
      );
      return List.generate(maps.length, (i) {
        return AppUsageData.fromMap(maps[i]);
      });
    }
  }
  
  // For demo purposes, add some dummy data
  Future<void> addDummyDataIfEmpty() async {
    await database;
    
    final List<BatteryUsage> batteryData = await getBatteryUsage();
    final List<AppUsageData> appUsageData = await getAppUsage();
    
    if (batteryData.isEmpty) {
      // Add dummy battery usage data
      final now = DateTime.now();
      
      for (int i = 24; i >= 0; i--) {
        final timestamp = now.subtract(Duration(hours: i));
        // Battery level decreases over the day
        final batteryLevel = 100 - (i % 24 * 3) + (i % 3 - 1) * 2;
        
        await insertBatteryUsage(BatteryUsage(
          batteryLevel: batteryLevel.clamp(10, 100).toInt(),
          batteryState: i >= 22 || i <= 6 ? 'charging' : 'discharging',
          timestamp: timestamp,
          chargeRate: i >= 22 || i <= 6 ? 0.5 : 0.0,
          dischargeRate: i >= 22 || i <= 6 ? 0.0 : 0.3,
          appUsage: {'Browser': 0.5, 'Maps': 0.3, 'Messages': 0.2},
        ));
      }
    }
    
    if (appUsageData.isEmpty) {
      // Add dummy app usage data
      final apps = [
        {
          'packageName': 'com.example.browser',
          'appName': 'Browser',
          'duration': const Duration(hours: 2, minutes: 15),
          'consumption': 4.2,
        },
        {
          'packageName': 'com.example.maps',
          'appName': 'Maps',
          'duration': const Duration(hours: 1, minutes: 30),
          'consumption': 3.7,
        },
        {
          'packageName': 'com.example.socialmedia',
          'appName': 'Social Media',
          'duration': const Duration(hours: 3, minutes: 45),
          'consumption': 7.8,
        },
        {
          'packageName': 'com.example.camera',
          'appName': 'Camera',
          'duration': const Duration(minutes: 25),
          'consumption': 2.5,
        },
        {
          'packageName': 'com.example.games',
          'appName': 'Games',
          'duration': const Duration(hours: 1, minutes: 10),
          'consumption': 6.3,
        },
      ];
      
      for (var app in apps) {
        final now = DateTime.now();
        final duration = app['duration'] as Duration;
        
        await insertAppUsage(AppUsageData(
          packageName: app['packageName'] as String,
          appName: app['appName'] as String,
          usageDuration: duration,
          startTime: now.subtract(duration + const Duration(minutes: 30)),
          endTime: now.subtract(const Duration(minutes: 30)),
          batteryConsumptionPercentage: app['consumption'] as double,
        ));
      }
    }
  }
} 
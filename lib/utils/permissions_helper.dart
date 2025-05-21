import 'dart:io';
import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';

class PermissionsHelper {
  static Future<bool> checkAppUsagePermission(BuildContext context) async {
    if (!Platform.isAndroid) {
      return true; // Only Android requires the special app usage permission
    }
    
    try {
      // This will throw an exception if permissions are not granted
      await AppUsage().getAppUsage(
        DateTime.now().subtract(const Duration(hours: 1)),
        DateTime.now(),
      );
      return true;
    } catch (e) {
      await _showAppUsagePermissionDialog(context);
      return false;
    }
  }

  static Future<void> _showAppUsagePermissionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('This app needs access to usage data to monitor battery consumption by apps.'),
                SizedBox(height: 10),
                Text('Please enable "Usage Data Access" permission in Settings.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                _openAppUsageSettings();
              },
            ),
          ],
        );
      },
    );
  }

  static void _openAppUsageSettings() {
    // On Android, this intent opens the Usage Access settings
    // However, we can't directly launch it from Flutter
    // In a real app, you'd use a native method channel or a plugin like app_settings
    
    // This is a fallback message
    print('Please go to Settings > Apps > Special Access > Usage Data Access and enable permission for this app');
  }
} 
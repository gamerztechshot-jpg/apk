// core/services/in_app_update_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InAppUpdateService {
  static const String _lastUpdateCheckKey = 'last_update_check';
  static const String _updateDismissedKey = 'update_dismissed';
  static const int _checkIntervalHours = 24; // Check for updates once per day

  /// Check if an update is available and show appropriate UI
  static Future<void> checkForUpdate(BuildContext context) async {
    // Only check on Android
    if (!Platform.isAndroid) return;

    try {
      // Check if we should skip this check
      if (await _shouldSkipUpdateCheck()) {
        return;
      }

      // Check for update availability
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // Show update dialog
        _showUpdateDialog(context, updateInfo);
      }
    } catch (e) {}
  }

  /// Check if we should skip the update check based on timing and user preferences
  static Future<bool> _shouldSkipUpdateCheck() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if user dismissed the update recently (within 24 hours)
    final dismissedTime = prefs.getInt(_updateDismissedKey);
    if (dismissedTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final hoursSinceDismissed = (now - dismissedTime) / (1000 * 60 * 60);
      if (hoursSinceDismissed < _checkIntervalHours) {
        return true;
      }
    }

    // Check if we checked recently (within 6 hours)
    final lastCheck = prefs.getInt(_lastUpdateCheckKey);
    if (lastCheck != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final hoursSinceLastCheck = (now - lastCheck) / (1000 * 60 * 60);
      if (hoursSinceLastCheck < 6) {
        return true;
      }
    }

    return false;
  }

  /// Show update dialog to user
  static void _showUpdateDialog(
    BuildContext context,
    AppUpdateInfo updateInfo,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('A new version of the app is available.'),
              const SizedBox(height: 8),
              Text(
                'Update priority: ${_getUpdatePriorityText(updateInfo.updatePriority)}',
              ),
              if (updateInfo.clientVersionStalenessDays != null)
                Text(
                  'Days since update: ${updateInfo.clientVersionStalenessDays}',
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => _dismissUpdate(context),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () => _startUpdate(context, updateInfo),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  /// Get user-friendly text for update priority
  static String _getUpdatePriorityText(int priority) {
    switch (priority) {
      case 0:
        return 'Low';
      case 1:
        return 'Medium';
      case 2:
        return 'High';
      case 3:
        return 'Critical';
      default:
        return 'Unknown';
    }
  }

  /// Start the update process
  static Future<void> _startUpdate(
    BuildContext context,
    AppUpdateInfo updateInfo,
  ) async {
    try {
      // Close the dialog first
      Navigator.of(context).pop();

      // Start flexible update
      await InAppUpdate.startFlexibleUpdate();

      // Show progress dialog
      _showUpdateProgressDialog(context);
    } catch (e) {
      _showUpdateErrorDialog(context);
    }
  }

  /// Show update progress dialog
  static void _showUpdateProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Updating...'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Please wait while the app updates.'),
            ],
          ),
        );
      },
    );
  }

  /// Show update error dialog
  static void _showUpdateErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Error'),
          content: const Text(
            'Unable to start the update. Please try again later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Dismiss the update dialog
  static Future<void> _dismissUpdate(BuildContext context) async {
    Navigator.of(context).pop();

    // Record dismissal time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _updateDismissedKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Record that we checked for updates
  static Future<void> _recordUpdateCheck() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastUpdateCheckKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Force check for updates (bypass timing restrictions)
  static Future<void> forceCheckForUpdate(BuildContext context) async {
    if (!Platform.isAndroid) return;

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        _showUpdateDialog(context, updateInfo);
      } else {
        _showNoUpdateDialog(context);
      }

      await _recordUpdateCheck();
    } catch (e) {
      _showUpdateErrorDialog(context);
    }
  }

  /// Show no update available dialog
  static void _showNoUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Updates'),
          content: const Text('You are using the latest version of the app.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Complete the flexible update
  static Future<void> completeUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {}
  }

  /// Check if update is in progress
  static Future<bool> isUpdateInProgress() async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      return updateInfo.updateAvailability ==
          UpdateAvailability.updateAvailable;
    } catch (e) {
      return false;
    }
  }
}

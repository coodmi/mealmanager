import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';
import 'deletion_policy_service.dart';

/// App launch-এ data deletion policy চালানোর scheduler।
/// SharedPreferences দিয়ে "last run date" track করে দিনে একবারের বেশি চলবে না।
class DeletionScheduler {
  static const _prefKey = 'deletion_last_run_date';

  /// App launch-এ call করা হবে।
  /// আজকে আগে run হয়নি হলে deletion চালাবে, নইলে skip করবে।
  static Future<void> runIfNeeded() async {
    final lastRun = await _getLastRunDate();
    final today = DateTime.now();

    if (lastRun != null &&
        lastRun.year == today.year &&
        lastRun.month == today.month &&
        lastRun.day == today.day) {
      log(
        'DeletionScheduler: already ran today, skipping.',
        name: 'DeletionScheduler',
      );
      return;
    }

    await DeletionPolicyService.runAll();
    await _saveRunDate();
  }

  /// SharedPreferences থেকে last run date পড়বে
  static Future<DateTime?> _getLastRunDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_prefKey);
      if (stored == null) return null;
      return DateTime.tryParse(stored);
    } catch (e) {
      log(
        'DeletionScheduler: failed to read last run date: $e',
        name: 'DeletionScheduler',
      );
      return null;
    }
  }

  /// আজকের date SharedPreferences-এ save করবে (yyyy-MM-dd format)
  static Future<void> _saveRunDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final formatted =
          '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';
      await prefs.setString(_prefKey, formatted);
    } catch (e) {
      log(
        'DeletionScheduler: failed to save run date: $e',
        name: 'DeletionScheduler',
      );
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles automatic daily meal entry for messes with mealEntryMode == 'auto'.
/// Should be called once per app session (e.g., from DashboardPage.initState).
class AutoMealService {
  static const _prefKey = 'auto_meal_last_run';

  /// Run auto meal entry if:
  ///   1. Mess is in 'auto' mode
  ///   2. Not already run today
  static Future<void> runIfNeeded() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check if already run today
      final prefs = await SharedPreferences.getInstance();
      final today = _todayKey();
      final lastRun = prefs.getString(_prefKey) ?? '';
      if (lastRun == today) return; // already done today

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final messId = userDoc.data()?['messId'] as String? ?? '';
      if (messId.isEmpty) return;

      final messDoc = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .get();
      final mode = messDoc.data()?['mealEntryMode'] as String? ?? 'manual';
      if (mode != 'auto') return;

      // Run auto entry
      await _createDailyMeals(messId);

      // Mark as done today
      await prefs.setString(_prefKey, today);
    } catch (_) {
      // Silent fail — don't disrupt app startup
    }
  }

  static Future<void> _createDailyMeals(String messId) async {
    final today = DateTime.now();
    final mealDate = DateTime(today.year, today.month, today.day);
    final monthKey = '${today.year}-${today.month.toString().padLeft(2, '0')}';

    // Get all active members
    final membersSnap = await FirebaseFirestore.instance
        .collection('messes')
        .doc(messId)
        .collection('members')
        .where('isActive', isEqualTo: true)
        .get();

    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    int writes = 0;

    for (final memberDoc in membersSnap.docs) {
      final data = memberDoc.data();
      final memberId = memberDoc.id;
      final memberName = data['name'] as String? ?? 'Member';

      // Read default meal preferences (defaults: all true if not set)
      final defaultMeals = data['defaultMeals'] as Map<String, dynamic>? ?? {};
      final wantsBreakfast = defaultMeals['breakfast'] as bool? ?? true;
      final wantsLunch = defaultMeals['lunch'] as bool? ?? true;
      final wantsDinner = defaultMeals['dinner'] as bool? ?? true;

      final mealTypes = <String>[];
      if (wantsBreakfast) mealTypes.add('breakfast');
      if (wantsLunch) mealTypes.add('lunch');
      if (wantsDinner) mealTypes.add('dinner');

      for (final mealType in mealTypes) {
        // Check if meal already exists for this member/type/date
        final existing = await db
            .collection('messes')
            .doc(messId)
            .collection('meals')
            .where('memberId', isEqualTo: memberId)
            .where('mealType', isEqualTo: mealType)
            .where('date', isEqualTo: Timestamp.fromDate(mealDate))
            .limit(1)
            .get();

        if (existing.docs.isNotEmpty) continue; // already exists

        final ref = db
            .collection('messes')
            .doc(messId)
            .collection('meals')
            .doc();

        batch.set(ref, {
          'messId': messId,
          'memberId': memberId,
          'memberName': memberName,
          'mealType': mealType,
          'date': Timestamp.fromDate(mealDate),
          'count': 1.0,
          'monthKey': monthKey,
          'isGuest': false,
          'guestName': null,
          'createdAt': Timestamp.now(),
          'createdBy': 'auto',
        });

        writes++;
        // Firestore batch limit is 500
        if (writes >= 490) break;
      }
      if (writes >= 490) break;
    }

    if (writes > 0) await batch.commit();
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

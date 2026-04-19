import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Determines the "running month" for a mess.
///
/// Rules:
/// - If current calendar month has NOT been closed → running month = current month
/// - If current calendar month HAS been closed → running month = next month
///   (but since next month hasn't started yet in the system, we still use current+1)
///
/// "Closed" means a document exists in messes/{messId}/monthSummaries/{monthKey}
class ActiveMonthService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Returns the running monthKey string e.g. "2026-04"
  static Future<String> getRunningMonthKey(String messId) async {
    final now = DateTime.now();
    final currentKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    try {
      final doc = await _db
          .collection('messes')
          .doc(messId)
          .collection('monthSummaries')
          .doc(currentKey)
          .get();

      if (!doc.exists) {
        // Current month not closed → it's the running month
        return currentKey;
      } else {
        // Current month closed → next month is running
        final next = DateTime(now.year, now.month + 1);
        return '${next.year}-${next.month.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      return currentKey;
    }
  }

  /// Returns the first and last day of the running month as a DateTimeRange
  static Future<DateTimeRange> getRunningMonthRange(String messId) async {
    final key = await getRunningMonthKey(messId);
    final parts = key.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final first = DateTime(year, month, 1);
    final last = DateTime(year, month + 1, 0); // last day of month
    return DateTimeRange(start: first, end: last);
  }
}

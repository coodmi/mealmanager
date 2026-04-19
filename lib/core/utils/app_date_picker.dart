import 'package:flutter/material.dart';
import '../services/active_month_service.dart';

/// Global date picker restricted to the running month.
/// Pass [messId] to determine the running month from Firestore.
/// Pass [initialDate] to pre-select a date (defaults to today or first of month).
/// Pass [overrideMonthKey] (format: "YYYY-MM") to bypass ActiveMonthService and
/// use that month's range directly (e.g., when user has switched months in the top bar).
class AppDatePicker {
  /// Computes the [DateTimeRange] for a given month key in "YYYY-MM" format.
  static DateTimeRange _rangeFromMonthKey(String monthKey) {
    final parts = monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final first = DateTime(year, month, 1);
    final last = DateTime(year, month + 1, 0); // last day of month
    return DateTimeRange(start: first, end: last);
  }

  static Future<DateTime?> show({
    required BuildContext context,
    required String messId,
    DateTime? initialDate,
    String?
    overrideMonthKey, // "YYYY-MM" — skips ActiveMonthService when provided
  }) async {
    final DateTimeRange range;

    if (overrideMonthKey != null) {
      // Use the override month's range directly without querying Firestore
      range = _rangeFromMonthKey(overrideMonthKey);
    } else {
      range = await ActiveMonthService.getRunningMonthRange(messId);
    }

    if (!context.mounted) return null;

    // Clamp initialDate within range: max(firstDay, min(lastDay, initialDate ?? now))
    final DateTime init = () {
      final date = initialDate ?? DateTime.now();
      if (date.isBefore(range.start)) return range.start;
      if (date.isAfter(range.end)) return range.end;
      return date;
    }();

    return showDatePicker(
      context: context,
      initialDate: init,
      firstDate: range.start,
      lastDate: range.end,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: const Color(0xFF2E7D32), // primaryGreen
          ),
        ),
        child: child!,
      ),
    );
  }
}

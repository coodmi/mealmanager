import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mealmanager/core/services/active_month_service.dart';

/// Deletion job-এর result summary।
class DeletionSummary {
  final String messId;
  final List<String> deletedMonths; // 6-month policy-তে delete হওয়া months
  final int totalDocumentsDeleted;
  final List<String> errors;
  final DateTime ranAt;

  const DeletionSummary({
    required this.messId,
    required this.deletedMonths,
    required this.totalDocumentsDeleted,
    required this.errors,
    required this.ranAt,
  });

  @override
  String toString() =>
      'DeletionSummary(messId: $messId, deletedMonths: $deletedMonths, '
      'totalDocumentsDeleted: $totalDocumentsDeleted, errors: ${errors.length}, ranAt: $ranAt)';
}

/// Data deletion policy enforce করার service।
/// 6-month policy (meals, expenses, transactions, withdrawals, monthSummaries)
/// এবং 40-day policy (notifications, chat messages) আলাদা code path-এ চালায়।
class DeletionPolicyService {
  /// সব mess-এর জন্য উভয় policy চালাবে
  static Future<void> runAll() async {
    final db = FirebaseFirestore.instance;

    // Step 1: current user নাও; null হলে return
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      log(
        'runAll: no authenticated user, skipping',
        name: 'DeletionPolicyService',
      );
      return;
    }
    final uid = user.uid;

    // Step 2: users/{uid} থেকে messIds list নাও
    List<String> messIds = [];
    try {
      final userDoc = await db.collection('users').doc(uid).get();
      final data = userDoc.data();
      if (data == null) {
        log(
          'runAll: user document not found for uid=$uid',
          name: 'DeletionPolicyService',
        );
        return;
      }
      final rawMessIds = data['messIds'];
      if (rawMessIds is List) {
        messIds = List<String>.from(rawMessIds);
      } else {
        // backward compat: single messId field
        final single = data['messId'] as String? ?? '';
        if (single.isNotEmpty) messIds = [single];
      }
    } catch (e, st) {
      log(
        'runAll: failed to fetch user messIds',
        name: 'DeletionPolicyService',
        error: e,
        stackTrace: st,
      );
      return;
    }

    // Step 3: messIds empty হলে return
    if (messIds.isEmpty) {
      log(
        'runAll: user has no joined messes, skipping',
        name: 'DeletionPolicyService',
      );
      return;
    }

    // Step 4 & 5: প্রতিটি messId-এর জন্য উভয় policy চালাও এবং aggregate করো
    int totalDeletedMonths = 0;
    int totalDocuments = 0;

    for (final messId in messIds) {
      // Step 4a: 6-month policy
      DeletionSummary summary6;
      try {
        summary6 = await run6MonthPolicy(messId);
        totalDeletedMonths += summary6.deletedMonths.length;
        totalDocuments += summary6.totalDocumentsDeleted;
      } catch (e, st) {
        log(
          'runAll: run6MonthPolicy failed for mess=$messId',
          name: 'DeletionPolicyService',
          error: e,
          stackTrace: st,
        );
        summary6 = DeletionSummary(
          messId: messId,
          deletedMonths: [],
          totalDocumentsDeleted: 0,
          errors: ['run6MonthPolicy failed: $e'],
          ranAt: DateTime.now(),
        );
      }

      // Step 4b: 40-day policy
      DeletionSummary summary40;
      try {
        summary40 = await run40DayPolicy(messId: messId, userId: uid);
        totalDocuments += summary40.totalDocumentsDeleted;
      } catch (e, st) {
        log(
          'runAll: run40DayPolicy failed for mess=$messId',
          name: 'DeletionPolicyService',
          error: e,
          stackTrace: st,
        );
        summary40 = DeletionSummary(
          messId: messId,
          deletedMonths: [],
          totalDocumentsDeleted: 0,
          errors: ['run40DayPolicy failed: $e'],
          ranAt: DateTime.now(),
        );
      }

      // Step 6: Manager role check — messes/{messId}/members/{uid} থেকে role check
      final bool anyDeleted =
          summary6.totalDocumentsDeleted > 0 ||
          summary40.totalDocumentsDeleted > 0;

      if (anyDeleted) {
        try {
          final memberDoc = await db
              .collection('messes')
              .doc(messId)
              .collection('members')
              .doc(uid)
              .get();
          final role = memberDoc.data()?['role'] as String? ?? '';

          if (role == 'manager') {
            // Manager-only notification — এই task-এ শুধু log (UI notification Task 9-এ)
            log(
              'runAll [MANAGER NOTIFICATION]: mess=$messId — '
              'deleted ${summary6.deletedMonths.length} month(s) '
              '(${summary6.totalDocumentsDeleted} docs via 6-month policy), '
              '${summary40.totalDocumentsDeleted} docs via 40-day policy. '
              'Total documents deleted: ${summary6.totalDocumentsDeleted + summary40.totalDocumentsDeleted}',
              name: 'DeletionPolicyService',
            );
          } else {
            // Regular member — notification skip
            log(
              'runAll: mess=$messId deletion complete (role=$role, notification skipped)',
              name: 'DeletionPolicyService',
            );
          }
        } catch (e, st) {
          log(
            'runAll: role check failed for mess=$messId uid=$uid',
            name: 'DeletionPolicyService',
            error: e,
            stackTrace: st,
          );
        }
      }
    }

    log(
      'runAll: complete — messIds=${messIds.length}, '
      'totalDeletedMonths=$totalDeletedMonths, totalDocuments=$totalDocuments',
      name: 'DeletionPolicyService',
    );

    // Policy (b): inactive mess auto-delete
    try {
      final inactiveDeleted = await runInactivityPolicy();
      log(
        'runAll: runInactivityPolicy complete — $inactiveDeleted messes deleted',
        name: 'DeletionPolicyService',
      );
    } catch (e, st) {
      log(
        'runAll: runInactivityPolicy failed',
        name: 'DeletionPolicyService',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// 6-month policy: meals, expenses, transactions, withdrawals, monthSummaries
  static Future<DeletionSummary> run6MonthPolicy(String messId) async {
    final db = FirebaseFirestore.instance;
    final deletedMonths = <String>[];
    final errors = <String>[];
    int totalDeleted = 0;

    // Step 1: running month নাও
    final runningMonthKey = await ActiveMonthService.getRunningMonthKey(messId);

    // Step 2: expired months বের করো
    final expiredMonths = getExpiredMonthKeys(runningMonthKey);

    // Step 3: expired months empty হলে early return
    if (expiredMonths.isEmpty) {
      log(
        'run6MonthPolicy: nothing to delete for mess $messId',
        name: 'DeletionPolicyService',
      );
      return DeletionSummary(
        messId: messId,
        deletedMonths: [],
        totalDocumentsDeleted: 0,
        errors: [],
        ranAt: DateTime.now(),
      );
    }

    // Step 4: প্রতিটি expired month process করো
    for (final expiredMonth in expiredMonths) {
      final refs = <DocumentReference>[];

      // Month date range বের করো
      final parts = expiredMonth.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final firstDay = DateTime(year, month, 1);
      final lastDay = DateTime(year, month + 1, 0, 23, 59, 59, 999);
      final firstTs = Timestamp.fromDate(firstDay);
      final lastTs = Timestamp.fromDate(lastDay);

      // 4a: meals — messId + date Timestamp within month
      try {
        final mealsSnap = await db
            .collection('meals')
            .where('messId', isEqualTo: messId)
            .where('date', isGreaterThanOrEqualTo: firstTs)
            .where('date', isLessThanOrEqualTo: lastTs)
            .get();
        refs.addAll(mealsSnap.docs.map((d) => d.reference));
      } catch (e, st) {
        final msg = 'meals query failed for $expiredMonth: $e';
        log(msg, name: 'DeletionPolicyService', error: e, stackTrace: st);
        errors.add(msg);
      }

      // 4b: expenses — messId + monthKey
      try {
        final expensesSnap = await db
            .collection('expenses')
            .where('messId', isEqualTo: messId)
            .where('monthKey', isEqualTo: expiredMonth)
            .get();
        refs.addAll(expensesSnap.docs.map((d) => d.reference));
      } catch (e, st) {
        final msg = 'expenses query failed for $expiredMonth: $e';
        log(msg, name: 'DeletionPolicyService', error: e, stackTrace: st);
        errors.add(msg);
      }

      // 4c: transactions — messId + monthKey
      try {
        final txSnap = await db
            .collection('transactions')
            .where('messId', isEqualTo: messId)
            .where('monthKey', isEqualTo: expiredMonth)
            .get();
        refs.addAll(txSnap.docs.map((d) => d.reference));
      } catch (e, st) {
        final msg = 'transactions query failed for $expiredMonth: $e';
        log(msg, name: 'DeletionPolicyService', error: e, stackTrace: st);
        errors.add(msg);
      }

      // 4d: withdrawals — messId + monthKey
      try {
        final wSnap = await db
            .collection('withdrawals')
            .where('messId', isEqualTo: messId)
            .where('monthKey', isEqualTo: expiredMonth)
            .get();
        refs.addAll(wSnap.docs.map((d) => d.reference));
      } catch (e, st) {
        final msg = 'withdrawals query failed for $expiredMonth: $e';
        log(msg, name: 'DeletionPolicyService', error: e, stackTrace: st);
        errors.add(msg);
      }

      // 4e: monthSummaries document ref
      final summaryRef = db
          .collection('messes')
          .doc(messId)
          .collection('monthSummaries')
          .doc(expiredMonth);
      refs.add(summaryRef);

      // 4f: dry-run log (Requirement 7.3)
      log(
        'run6MonthPolicy [dry-run]: mess=$messId month=$expiredMonth '
        'will delete ${refs.length} documents',
        name: 'DeletionPolicyService',
      );

      // 4g: batch delete
      final deleted = await batchDelete(refs);
      totalDeleted += deleted;
      if (deleted > 0 || refs.isNotEmpty) {
        deletedMonths.add(expiredMonth);
      }
    }

    final summary = DeletionSummary(
      messId: messId,
      deletedMonths: deletedMonths,
      totalDocumentsDeleted: totalDeleted,
      errors: errors,
      ranAt: DateTime.now(),
    );

    log('run6MonthPolicy: $summary', name: 'DeletionPolicyService');

    return summary;
  }

  /// 40-day policy: notifications + chat messages
  /// NOTE: transactions, meals, withdrawals এই method-এ কখনো touch করা হয় না (policy scope isolation)
  static Future<DeletionSummary> run40DayPolicy({
    required String messId,
    required String userId,
  }) async {
    final db = FirebaseFirestore.instance;
    final errors = <String>[];
    final refs = <DocumentReference>[];

    // Step 1: cutoff date নাও
    final cutoff = get40DayCutoff();

    // Step 2: Timestamp তৈরি করো
    final cutoffTimestamp = Timestamp.fromDate(cutoff);

    // Step 3: users/{userId}/notifications query — createdAt < cutoffTimestamp
    try {
      final notifSnap = await db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('createdAt', isLessThan: cutoffTimestamp)
          .get();
      refs.addAll(notifSnap.docs.map((d) => d.reference));
    } catch (e, st) {
      final msg = 'notifications query failed for user $userId: $e';
      log(msg, name: 'DeletionPolicyService', error: e, stackTrace: st);
      errors.add(msg);
    }

    // Step 4: messes/{messId}/chats query — createdAt < cutoffTimestamp
    try {
      final chatsSnap = await db
          .collection('messes')
          .doc(messId)
          .collection('chats')
          .where('createdAt', isLessThan: cutoffTimestamp)
          .get();
      refs.addAll(chatsSnap.docs.map((d) => d.reference));
    } catch (e, st) {
      final msg = 'chats query failed for mess $messId: $e';
      log(msg, name: 'DeletionPolicyService', error: e, stackTrace: st);
      errors.add(msg);
    }

    // Step 5: dry-run log
    log(
      'run40DayPolicy [dry-run]: mess=$messId user=$userId '
      'will delete ${refs.length} documents (cutoff: $cutoff)',
      name: 'DeletionPolicyService',
    );

    // Step 6: batch delete
    final totalDeleted = await batchDelete(refs);

    final summary = DeletionSummary(
      messId: messId,
      deletedMonths: [], // 40-day policy-তে প্রযোজ্য নয়
      totalDocumentsDeleted: totalDeleted,
      errors: errors,
      ranAt: DateTime.now(),
    );

    log('run40DayPolicy: $summary', name: 'DeletionPolicyService');

    return summary;
  }

  /// Expired monthKeys বের করবে (running month থেকে 6 calendar month আগের চেয়ে পুরনো)
  ///
  /// [runningMonthKey] — `YYYY-MM` format, e.g. "2025-07"
  ///
  /// Returns months strictly older than 6 calendar months before [runningMonthKey],
  /// newest expired first. Checks up to 12 months back for performance.
  ///
  /// Example: runningMonthKey = "2025-07" → cutoff = "2025-01"
  ///          → returns ["2024-12", "2024-11", "2024-10", "2024-09", "2024-08", "2024-07"]
  static List<String> getExpiredMonthKeys(String runningMonthKey) {
    // Parse YYYY-MM
    final parts = runningMonthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    // Cutoff = running month - 6 calendar months
    // Months strictly OLDER than cutoff are expired
    // i.e., monthKey < cutoffYear-cutoffMonth
    int cutoffYear = year;
    int cutoffMonth = month - 6;
    while (cutoffMonth <= 0) {
      cutoffMonth += 12;
      cutoffYear -= 1;
    }

    // Collect expired months: from (cutoff - 1) going back 12 months
    final expired = <String>[];
    int checkYear = cutoffYear;
    int checkMonth = cutoffMonth - 1;
    if (checkMonth <= 0) {
      checkMonth += 12;
      checkYear -= 1;
    }

    for (int i = 0; i < 12; i++) {
      final mm = checkMonth.toString().padLeft(2, '0');
      expired.add('$checkYear-$mm');

      checkMonth -= 1;
      if (checkMonth <= 0) {
        checkMonth += 12;
        checkYear -= 1;
      }
    }

    return expired;
  }

  /// 40-day cutoff date বের করবে
  static DateTime get40DayCutoff() {
    return DateTime.now().subtract(const Duration(days: 40));
  }

  /// Mess-এ activity হলে `lastActivityAt` update করো (fire-and-forget safe)
  static Future<void> updateLastActivity(String messId) async {
    try {
      await FirebaseFirestore.instance.collection('messes').doc(messId).update({
        'lastActivityAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      log(
        'updateLastActivity: failed for mess=$messId',
        name: 'DeletionPolicyService',
        error: e,
        stackTrace: st,
      );
      // fire-and-forget — error log করে continue
    }
  }

  /// Policy (b): 180 দিনের বেশি inactive mess soft-delete করো।
  /// Returns: deleted mess count
  static Future<int> runInactivityPolicy() async {
    final db = FirebaseFirestore.instance;
    final cutoff = DateTime.now().subtract(const Duration(days: 180));
    final cutoffTs = Timestamp.fromDate(cutoff);
    int deletedCount = 0;

    // lastActivityAt < cutoff এমন messes query করো
    QuerySnapshot<Map<String, dynamic>> messesSnap;
    try {
      messesSnap = await db
          .collection('messes')
          .where('lastActivityAt', isLessThan: cutoffTs)
          .get();
    } catch (e, st) {
      log(
        'runInactivityPolicy: messes query failed',
        name: 'DeletionPolicyService',
        error: e,
        stackTrace: st,
      );
      return 0;
    }

    // lastActivityAt না থাকলে createdAt fallback — in-memory filter
    final QuerySnapshot<Map<String, dynamic>> allMessesSnap = await db
        .collection('messes')
        .get();
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> noActivityDocs =
        allMessesSnap.docs.where((doc) {
          final data = doc.data();
          if (data.containsKey('lastActivityAt'))
            return false; // already queried
          final createdAt = data['createdAt'];
          if (createdAt is Timestamp) {
            return createdAt.toDate().isBefore(cutoff);
          }
          return false;
        }).toList();

    // Combine: lastActivityAt-based + createdAt fallback (deduplicate)
    final Set<String> processedIds = messesSnap.docs.map((d) => d.id).toSet();
    final List<Map<String, dynamic>> inactiveMessData = [];
    for (final doc in messesSnap.docs) {
      final docData = Map<String, dynamic>.from(doc.data());
      inactiveMessData.add({'id': doc.id, ...docData});
    }
    for (final doc in noActivityDocs) {
      if (!processedIds.contains(doc.id)) {
        final docData = Map<String, dynamic>.from(doc.data());
        inactiveMessData.add({'id': doc.id, ...docData});
      }
    }

    for (final messData in inactiveMessData) {
      final messId = messData['id'] as String;
      try {
        final data = Map<String, dynamic>.from(messData)..remove('id');

        // 1. deleted_messes/{messId} তে write করো
        await db.collection('deleted_messes').doc(messId).set({
          ...data,
          'deletedAt': Timestamp.now(),
          'deletedBy': 'system',
          'isDeleted': true,
          'deletionReason': 'inactivity',
        });

        // 2. messes/{messId} root doc delete করো
        await db.collection('messes').doc(messId).delete();

        // 3. members subcollection update করো
        final membersSnap = await db
            .collection('messes')
            .doc(messId)
            .collection('members')
            .get();

        const chunkSize = 500;
        for (int i = 0; i < membersSnap.docs.length; i += chunkSize) {
          final chunk = membersSnap.docs.sublist(
            i,
            (i + chunkSize).clamp(0, membersSnap.docs.length),
          );
          final batch = db.batch();
          for (final memberDoc in chunk) {
            batch.update(memberDoc.reference, {'messId': '', 'role': 'member'});
          }
          await batch.commit();
        }

        deletedCount++;
        log(
          'runInactivityPolicy: soft-deleted mess=$messId (${membersSnap.docs.length} members updated)',
          name: 'DeletionPolicyService',
        );
      } catch (e, st) {
        log(
          'runInactivityPolicy: error processing mess=$messId',
          name: 'DeletionPolicyService',
          error: e,
          stackTrace: st,
        );
        // error হলে log করে continue
      }
    }

    log(
      'runInactivityPolicy: complete — $deletedCount inactive messes deleted',
      name: 'DeletionPolicyService',
    );
    return deletedCount;
  }

  /// Batch delete helper — max 500 per Firestore batch
  static Future<int> batchDelete(List<DocumentReference> refs) async {
    if (refs.isEmpty) return 0;

    const chunkSize = 500;
    int deletedCount = 0;

    for (int i = 0; i < refs.length; i += chunkSize) {
      final chunk = refs.sublist(i, (i + chunkSize).clamp(0, refs.length));
      final batch = FirebaseFirestore.instance.batch();

      for (final ref in chunk) {
        batch.delete(ref);
      }

      try {
        await batch.commit();
        deletedCount += chunk.length;
      } catch (e, st) {
        log(
          'batchDelete: batch ${i ~/ chunkSize} failed (${chunk.length} docs skipped)',
          name: 'DeletionPolicyService',
          error: e,
          stackTrace: st,
        );
        // continue to next chunk — error resilience
      }
    }

    return deletedCount;
  }
}

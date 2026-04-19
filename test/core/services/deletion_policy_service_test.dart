import 'package:flutter_test/flutter_test.dart';
import 'package:mealmanager/core/services/deletion_policy_service.dart';

void main() {
  group('DeletionPolicyService.getExpiredMonthKeys', () {
    test('2025-07 → cutoff 2025-01 → expired starts at 2024-12', () {
      final result = DeletionPolicyService.getExpiredMonthKeys('2025-07');
      expect(result.first, '2024-12');
    });

    test('2025-07 → returns 12 months', () {
      final result = DeletionPolicyService.getExpiredMonthKeys('2025-07');
      expect(result.length, 12);
    });

    test('2025-07 → running month not in list', () {
      final result = DeletionPolicyService.getExpiredMonthKeys('2025-07');
      expect(result.contains('2025-07'), isFalse);
    });

    test('2025-07 → 6 most recent closed months not in list', () {
      final result = DeletionPolicyService.getExpiredMonthKeys('2025-07');
      // 6 most recent closed: 2025-06, 2025-05, 2025-04, 2025-03, 2025-02, 2025-01
      for (final m in [
        '2025-06',
        '2025-05',
        '2025-04',
        '2025-03',
        '2025-02',
        '2025-01',
      ]) {
        expect(result.contains(m), isFalse, reason: '$m should not be expired');
      }
    });

    test('2025-07 → newest expired first order', () {
      final result = DeletionPolicyService.getExpiredMonthKeys('2025-07');
      expect(result[0], '2024-12');
      expect(result[1], '2024-11');
      expect(result[2], '2024-10');
    });

    test('2025-01 → cutoff 2024-07 → expired starts at 2024-06', () {
      final result = DeletionPolicyService.getExpiredMonthKeys('2025-01');
      expect(result.first, '2024-06');
    });

    test('2025-01 → running month not in list', () {
      final result = DeletionPolicyService.getExpiredMonthKeys('2025-01');
      expect(result.contains('2025-01'), isFalse);
    });

    test('2025-01 → 6 most recent closed months not in list', () {
      final result = DeletionPolicyService.getExpiredMonthKeys('2025-01');
      // 6 most recent closed: 2024-12, 2024-11, 2024-10, 2024-09, 2024-08, 2024-07
      for (final m in [
        '2024-12',
        '2024-11',
        '2024-10',
        '2024-09',
        '2024-08',
        '2024-07',
      ]) {
        expect(result.contains(m), isFalse, reason: '$m should not be expired');
      }
    });

    test(
      'year boundary: 2025-03 → cutoff 2024-09 → expired starts at 2024-08',
      () {
        final result = DeletionPolicyService.getExpiredMonthKeys('2025-03');
        expect(result.first, '2024-08');
        expect(result.contains('2024-09'), isFalse);
      },
    );

    test('all returned months are strictly older than cutoff', () {
      const running = '2025-07';
      // cutoff = 2025-01; expired must be < 2025-01
      final result = DeletionPolicyService.getExpiredMonthKeys(running);
      for (final key in result) {
        final parts = key.split('-');
        final y = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        // Must be before 2025-01
        final isOlder = y < 2025 || (y == 2025 && m < 1);
        expect(
          isOlder,
          isTrue,
          reason: '$key should be strictly older than 2025-01',
        );
      }
    });
  });

  group('DeletionPolicyService.get40DayCutoff', () {
    test('returns a date approximately 40 days ago', () {
      final before = DateTime.now().subtract(
        const Duration(days: 40, seconds: 1),
      );
      final cutoff = DeletionPolicyService.get40DayCutoff();
      final after = DateTime.now().subtract(const Duration(days: 40));
      // cutoff should be between before and after (within a second)
      expect(cutoff.isAfter(before), isTrue);
      expect(
        cutoff.isBefore(DateTime.now().subtract(const Duration(days: 39))),
        isTrue,
      );
    });

    test('cutoff is in the past', () {
      final cutoff = DeletionPolicyService.get40DayCutoff();
      expect(cutoff.isBefore(DateTime.now()), isTrue);
    });
  });
}

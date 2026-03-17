import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_model.dart';

class FirebaseMealService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a meal
  static Future<String> addMeal({
    required String messId,
    required String memberId,
    required String memberName,
    required String mealType,
    required DateTime date,
    double count = 1.0,
    String? createdBy,
  }) async {
    try {
      // Normalize date to start of day
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // Check if meal already exists
      final existing = await _firestore
          .collection('meals')
          .where('messId', isEqualTo: messId)
          .where('memberId', isEqualTo: memberId)
          .where('mealType', isEqualTo: mealType)
          .where('date', isEqualTo: Timestamp.fromDate(normalizedDate))
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('Meal already exists for this member on this date');
      }

      final meal = MealModel(
        id: '',
        memberId: memberId,
        memberName: memberName,
        mealType: mealType,
        date: normalizedDate,
        count: count,
        messId: messId,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );

      final docRef = await _firestore
          .collection('meals')
          .add(meal.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add meal: $e');
    }
  }

  // Remove a meal
  static Future<void> removeMeal(String mealId) async {
    try {
      await _firestore.collection('meals').doc(mealId).delete();
    } catch (e) {
      throw Exception('Failed to remove meal: $e');
    }
  }

  // Get meals for a specific date and mess
  static Stream<List<MealModel>> getMealsByDate({
    required String messId,
    required DateTime date,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    return _firestore
        .collection('meals')
        .where('messId', isEqualTo: messId)
        .where('date', isEqualTo: Timestamp.fromDate(normalizedDate))
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => MealModel.fromFirestore(doc)).toList(),
        );
  }

  // Get meals for a specific member
  static Stream<List<MealModel>> getMealsByMember({
    required String messId,
    required String memberId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _firestore
        .collection('meals')
        .where('messId', isEqualTo: messId)
        .where('memberId', isEqualTo: memberId)
        .snapshots()
        .map((snapshot) {
          var meals = snapshot.docs
              .map((doc) => MealModel.fromFirestore(doc))
              .toList();

          // Filter by date in memory
          if (startDate != null) {
            meals = meals
                .where((meal) => !meal.date.isBefore(startDate))
                .toList();
          }
          if (endDate != null) {
            meals = meals.where((meal) => !meal.date.isAfter(endDate)).toList();
          }

          return meals;
        });
  }

  // Get meal count for a member in a date range
  static Future<Map<String, dynamic>> getMemberMealStats({
    required String messId,
    required String memberId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('meals')
          .where('messId', isEqualTo: messId)
          .where('memberId', isEqualTo: memberId)
          .get();

      double totalMeals = 0;
      int breakfastCount = 0;
      int lunchCount = 0;
      int dinnerCount = 0;

      for (var doc in snapshot.docs) {
        final meal = MealModel.fromFirestore(doc);

        // Filter by date in memory
        if (meal.date.isBefore(startDate) || meal.date.isAfter(endDate)) {
          continue;
        }

        totalMeals += meal.count;

        if (meal.mealType == 'breakfast') breakfastCount++;
        if (meal.mealType == 'lunch') lunchCount++;
        if (meal.mealType == 'dinner') dinnerCount++;
      }

      return {
        'totalMeals': totalMeals,
        'breakfast': breakfastCount,
        'lunch': lunchCount,
        'dinner': dinnerCount,
      };
    } catch (e) {
      throw Exception('Failed to get meal stats: $e');
    }
  }

  // Get daily meal summary
  static Future<Map<String, int>> getDailyMealSummary({
    required String messId,
    required DateTime date,
  }) async {
    try {
      final normalizedDate = DateTime(date.year, date.month, date.day);

      final snapshot = await _firestore
          .collection('meals')
          .where('messId', isEqualTo: messId)
          .get();

      int breakfastCount = 0;
      int lunchCount = 0;
      int dinnerCount = 0;

      for (var doc in snapshot.docs) {
        final meal = MealModel.fromFirestore(doc);

        // Filter by date in memory
        if (meal.date.year != normalizedDate.year ||
            meal.date.month != normalizedDate.month ||
            meal.date.day != normalizedDate.day) {
          continue;
        }

        if (meal.mealType == 'breakfast') breakfastCount++;
        if (meal.mealType == 'lunch') lunchCount++;
        if (meal.mealType == 'dinner') dinnerCount++;
      }

      return {
        'breakfast': breakfastCount,
        'lunch': lunchCount,
        'dinner': dinnerCount,
        'total': breakfastCount + lunchCount + dinnerCount,
      };
    } catch (e) {
      throw Exception('Failed to get daily summary: $e');
    }
  }

  // Update meal count
  static Future<void> updateMealCount({
    required String mealId,
    required double count,
  }) async {
    try {
      await _firestore.collection('meals').doc(mealId).update({'count': count});
    } catch (e) {
      throw Exception('Failed to update meal count: $e');
    }
  }

  // Get all members who had a specific meal type on a date
  static Stream<List<MealModel>> getMealsByTypeAndDate({
    required String messId,
    required String mealType,
    required DateTime date,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    return _firestore
        .collection('meals')
        .where('messId', isEqualTo: messId)
        .snapshots()
        .map((snapshot) {
          // Filter by meal type and date in memory to avoid composite index
          return snapshot.docs
              .map((doc) => MealModel.fromFirestore(doc))
              .where(
                (meal) =>
                    meal.mealType == mealType &&
                    meal.date.year == normalizedDate.year &&
                    meal.date.month == normalizedDate.month &&
                    meal.date.day == normalizedDate.day,
              )
              .toList();
        });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class MealModel {
  final String id;
  final String memberId;
  final String memberName;
  final String mealType; // 'breakfast', 'lunch', 'dinner'
  final DateTime date;
  final double count; // 1.0, 0.5, etc.
  final String messId;
  final DateTime createdAt;
  final String? createdBy;

  MealModel({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.mealType,
    required this.date,
    required this.count,
    required this.messId,
    required this.createdAt,
    this.createdBy,
  });

  factory MealModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MealModel(
      id: doc.id,
      memberId: data['memberId'] ?? '',
      memberName: data['memberName'] ?? '',
      mealType: data['mealType'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      count: (data['count'] ?? 1.0).toDouble(),
      messId: data['messId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'mealType': mealType,
      'date': Timestamp.fromDate(date),
      'count': count,
      'messId': messId,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  MealModel copyWith({
    String? id,
    String? memberId,
    String? memberName,
    String? mealType,
    DateTime? date,
    double? count,
    String? messId,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return MealModel(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      mealType: mealType ?? this.mealType,
      date: date ?? this.date,
      count: count ?? this.count,
      messId: messId ?? this.messId,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

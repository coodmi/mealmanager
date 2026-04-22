import 'package:cloud_firestore/cloud_firestore.dart';

class TaskScheduleModel {
  final String id;
  final String taskName;
  final String memberId;
  final String memberName;
  final DateTime date;
  final String messId;
  final bool isCompleted;
  final DateTime createdAt;

  TaskScheduleModel({
    required this.id,
    required this.taskName,
    required this.memberId,
    required this.memberName,
    required this.date,
    required this.messId,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory TaskScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskScheduleModel(
      id: doc.id,
      taskName: data['taskName'] ?? '',
      memberId: data['memberId'] ?? '',
      memberName: data['memberName'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      messId: data['messId'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'taskName': taskName,
    'memberId': memberId,
    'memberName': memberName,
    'date': Timestamp.fromDate(date),
    'messId': messId,
    'isCompleted': isCompleted,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

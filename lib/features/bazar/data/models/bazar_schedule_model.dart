import 'package:cloud_firestore/cloud_firestore.dart';

class BazarScheduleEntry {
  final String memberId;
  final String memberName;
  final DateTime date;

  BazarScheduleEntry({
    required this.memberId,
    required this.memberName,
    required this.date,
  });

  factory BazarScheduleEntry.fromMap(Map<String, dynamic> data) {
    return BazarScheduleEntry(
      memberId: data['memberId'] ?? '',
      memberName: data['memberName'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'memberId': memberId,
    'memberName': memberName,
    'date': Timestamp.fromDate(date),
  };
}

import 'package:cloud_firestore/cloud_firestore.dart';

class MemberModel {
  final String id;
  final String name;
  final String phone;
  final String messId;
  final double balance;
  final bool isActive;
  final DateTime joinedDate;
  final String? email;
  final String? avatarUrl;

  MemberModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.messId,
    this.balance = 0.0,
    this.isActive = true,
    required this.joinedDate,
    this.email,
    this.avatarUrl,
  });

  factory MemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemberModel(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      messId: data['messId'] ?? '',
      balance: (data['balance'] ?? 0.0).toDouble(),
      isActive: data['isActive'] ?? true,
      joinedDate: (data['joinedDate'] as Timestamp).toDate(),
      email: data['email'],
      avatarUrl: data['avatarUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'messId': messId,
      'balance': balance,
      'isActive': isActive,
      'joinedDate': Timestamp.fromDate(joinedDate),
      'email': email,
      'avatarUrl': avatarUrl,
    };
  }

  MemberModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? messId,
    double? balance,
    bool? isActive,
    DateTime? joinedDate,
    String? email,
    String? avatarUrl,
  }) {
    return MemberModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      messId: messId ?? this.messId,
      balance: balance ?? this.balance,
      isActive: isActive ?? this.isActive,
      joinedDate: joinedDate ?? this.joinedDate,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

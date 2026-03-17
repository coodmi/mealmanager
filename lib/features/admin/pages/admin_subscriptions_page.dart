import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/admin_card.dart';

class AdminSubscriptionsPage extends StatelessWidget {
  const AdminSubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AdminCard(
              padding: EdgeInsets.zero,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('subscriptions')
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final docs = snap.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.workspace_premium_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No subscriptions yet',
                            style: TextStyle(color: AppColors.textLight),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            _th('User', flex: 3),
                            _th('Plan', flex: 2),
                            _th('Price', flex: 2),
                            _th('Start', flex: 2),
                            _th('Expiry', flex: 2),
                            _th('Status', flex: 2),
                            _th('Actions', flex: 2),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) => _SubRow(
                            docId: docs[i].id,
                            data: docs[i].data() as Map<String, dynamic>,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _th(String label, {int flex = 1}) => Expanded(
    flex: flex,
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.textLight,
      ),
    ),
  );
}

class _SubRow extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const _SubRow({required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final userName = data['userName'] as String? ?? '—';
    final plan = data['plan'] as String? ?? '—';
    final price = data['price'] ?? 0;
    final startTs = data['startDate'] as Timestamp?;
    final expiryTs = data['expiryDate'] as Timestamp?;
    final start = startTs != null
        ? '${startTs.toDate().day}/${startTs.toDate().month}/${startTs.toDate().year}'
        : '—';
    final expiry = expiryTs != null
        ? '${expiryTs.toDate().day}/${expiryTs.toDate().month}/${expiryTs.toDate().year}'
        : '—';
    final isActive = data['isActive'] != false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              userName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(plan, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '৳$price',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              start,
              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              expiry,
              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isActive ? 'Active' : 'Expired',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.green : Colors.red,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'extend',
                  child: Text('Extend 30 days'),
                ),
                const PopupMenuItem(value: 'cancel', child: Text('Cancel')),
              ],
              onSelected: (action) async {
                if (action == 'extend' && expiryTs != null) {
                  final newExpiry = expiryTs.toDate().add(
                    const Duration(days: 30),
                  );
                  await FirebaseFirestore.instance
                      .collection('subscriptions')
                      .doc(docId)
                      .update({'expiryDate': Timestamp.fromDate(newExpiry)});
                } else if (action == 'cancel') {
                  await FirebaseFirestore.instance
                      .collection('subscriptions')
                      .doc(docId)
                      .update({'isActive': false});
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
